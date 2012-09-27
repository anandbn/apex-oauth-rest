tResource(urlMapping='/dotversion/refreshToken')
global with sharing class SFDCRefreshTokenService{


    @HttpPost
    global static String exchangeCodeForRefreshToken(String code,String client_id,String client_secret,String redirect_uri,String orgType) {
        RestRequest restReq = RestContext.request;
        System.debug('>>>>>>>>>>> About to make HTTP Callout using code:'+code);
        System.debug('>>>>>>>>>>> client_id:'+client_id);
        System.debug('>>>>>>>>>>> client_secret:'+client_secret);
        System.debug('>>>>>>>>>>> redirect_uri:'+redirect_uri);
        System.debug('>>>>>>>>>>> orgType:'+orgType);
        
        
        Http h = new Http();

         // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint 
        String loginEndpoint = 'https://login.salesforce.com';
        if(orgType=='sandbox'){
            loginEndpoint = 'https://test.salesforce.com';
        }
        String urlToPost = loginEndpoint+'/services/oauth2/token?code=';
        urlToPost +=code;
        urlToPost +='&grant_type=authorization_code';
        urlToPost +='&client_id='+client_id;
        urlToPost +='&client_secret='+client_secret;
        urlToPost +='&redirect_uri='+redirect_uri;
        HttpRequest req = new HttpRequest();
        System.debug('>>>>>>>>>>> urlToPost:'+urlToPost);
        req.setEndpoint(urlToPost);
        req.setMethod('POST');
    
        // Send the request, and return a response 
        
        HttpResponse res = h.send(req);
        
        System.debug('>>>>>>>>>>> res.getBody():'+res.getBody());
        JSONParser parser = JSON.createParser(res.getBody());

        String accessToken,refreshToken,apiEndpoint,orgId,idService,username,email,name;
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                String fieldName = parser.getText();
                parser.nextToken();
                if(fieldName == 'refresh_token') {
                    refreshToken = parser.getText();
                }else if(fieldName == 'access_token') {
                    accessToken = parser.getText();
                }else if(fieldName == 'id'){
                    idService = parser.getText();
                }else if(fieldName == 'instance_url'){
                    apiEndpoint=parser.getText();
                }
            }
        }
        System.debug('>>>>>>>>>>> apiEndpoint:'+apiEndpoint);
        System.debug('>>>>>>>>>>> refreshToken:'+refreshToken);
        System.debug('>>>>>>>>>>> accessToken:'+accessToken);
        System.debug('>>>>>>>>>>> idService:'+idService);
        
        req = new HttpRequest();
        System.debug('>>>>>>>>>>> urlToPost:'+idService);
        req.setEndpoint(idService);
        req.setHeader('Authorization','OAuth '+accessToken);
        req.setMethod('GET');
        res = h.send(req);
        res.getHeader('Location');
        req = new HttpRequest();
        System.debug('>>>>>>>>>>> urlToPost:'+res.getHeader('Location'));
        req.setEndpoint(res.getHeader('Location'));
        req.setHeader('Authorization','OAuth '+accessToken);
        req.setMethod('GET');
        res = h.send(req);
        System.debug('>>>>>>>>>>> res.getBody():'+res.getBody());
        
        parser = JSON.createParser(res.getBody());
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                String fieldName = parser.getText();
                parser.nextToken();
                if(fieldName == 'username') {
                    username = parser.getText();
                }else if(fieldName == 'organization_id') {
                    orgId = parser.getText();
                }else if(fieldName == 'email') {
                    email = parser.getText();
                }else if(fieldName == 'display_name') {
                    name = parser.getText();
                }
            }
        }
        System.debug('>>>>>>>>>> Checking for existing user record matching username :'+username);
        List<Dot_Version_User__c> usrList = [select Id from Dot_Version_User__c where Username__c=:username];
        System.debug('>>>>>>>>>> Matching User:'+usrList);
        if(usrList.isEmpty()){
            System.debug('>>>>>>>>>> Checking for existing user record matching partial username :'+username);
            String partialUsrName = username.substring(0,username.lastIndexOf('.'));
            usrList = [select Id from Dot_Version_User__c where Username__c=:partialUsrName];
            System.debug('>>>>>>>>>> Matching User - Partial username:'+usrList);
        }
        Dot_Version_User__c usr;
        Organization__c org;
        List<Organization__c> orgs;
        if(usrList.isEmpty()){
            usr = new Dot_Version_User__c(Username__c=username,Email__c=email,First_Name__c=name.split(' ')[0],
                                          Last_Name__c=name.split(' ')[1]);
            insert usr;
            System.debug('>>>>>>>>>>>>> User:'+usr);
            org = new Organization__c(Dot_Version_User__c=usr.Id,Org_Id__c=orgId,Org_Type__c=getOrgType(apiEndpoint),
                                      Api_Endpoint__c=apiEndpoint,Refresh_Token__c=refreshToken,
                                      Access_Token__c=accessToken,Time_Of_Day__c='1',AM_or_PM__c='AM',
                                      Metadata_Types__c='CustomObject;Layout;Profile',
                                      Frequency__c='Daily');
            System.debug('>>>>>>>>>>>>> Org:'+org);
            insert org;
        }else{
            usr= usrList[0];
            orgs = [SELECT  Id,AM_or_PM__c,Dot_Version_User__c,Frequency__c,Metadata_Types__c,
                            Org_Id__c,Org_Type__c,Status_Message__c,Status__c,Time_of_Day__c,Timezone__c,
                            API_Endpoint__c
                    from Organization__c 
                    where Org_Id__c=:orgId];
            if(orgs.IsEmpty()){
                org = new Organization__c(Dot_Version_User__c=usr.Id,Org_Id__c=orgId,Org_Type__c=getOrgType(apiEndpoint),
                                          Api_Endpoint__c=apiEndpoint,Refresh_Token__c=refreshToken,
                                          Access_Token__c=accessToken,Time_Of_Day__c='1',AM_or_PM__c='AM',
                                          Metadata_Types__c='ApexClass; ApexComponent; ApexPage; ApexTrigger',
                                          Frequency__c='Daily');
                System.debug('>>>>>>>>>>>>> Org:'+org);
                insert org;
            }else{
                org = orgs[0];
            }
            System.debug('>>>>>>>>>>>>> Org:'+org);
        }
        
        return '{"status":"Success","username":"'+username+'","org_id":"'+org.id+'"}';
        
    }
 
 
    private static String getOrgType(String apiEndpoint){
        if(apiEndpoint.startsWith('https://na')){
            return 'Production';
        }else if (apiEndpoint.indexOf('my.salesforce.com')>-1){
            return 'Production';
        }else {
            return 'Sandbox';
        }
    }
    
    
    

}
