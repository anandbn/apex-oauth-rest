@RestResource(urlMapping='/dotversion/accessToken/*')
global with sharing class SFDCAccessTokenService{


    @HttpPost
    global static String exchangeCodeForRefreshToken(String client_id,String client_secret,String redirect_uri,String orgType) {
 
        System.debug('>>>>>>>>>>> client_id:'+client_id);
        System.debug('>>>>>>>>>>> client_secret:'+client_secret);
        System.debug('>>>>>>>>>>> redirect_uri:'+redirect_uri);
        System.debug('>>>>>>>>>>> orgType:'+orgType);
       
        RestRequest restReq = RestContext.request;
        String orgId = restReq.requestURI.substring(restReq.requestURI.lastIndexOf('/')+1);
        
        Organization__c org = [select Refresh_Token__c from Organization__c where Id =:orgId];
        //System.debug('>>>>>>>>>>> About to make HTTP Callout using refresh_token:'+org.Refresh_Token__c);
        
        Http h = new Http();

        String loginEndpoint = 'https://login.salesforce.com';
        if(orgType=='sandbox'){
            loginEndpoint = 'https://test.salesforce.com';
        }

         // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint 
        String urlToPost = loginEndpoint+'/services/oauth2/token?';
        urlToPost +='grant_type=refresh_token';
        urlToPost +='&client_id='+client_id;
        urlToPost +='&client_secret='+client_secret;
        urlToPost +='&refresh_token='+org.Refresh_Token__c;
        urlToPost +='&redirect_uri='+redirect_uri;
        HttpRequest req = new HttpRequest();
        System.debug('>>>>>>>>>>> urlToPost:'+urlToPost);
        req.setEndpoint(urlToPost);
        req.setMethod('POST');
    
        // Send the request, and return a response 
        
        HttpResponse res = h.send(req);
        //System.debug('>>>>>>>>>>> res.body:'+res.getBody());
        
        JSONParser parser = JSON.createParser(res.getBody());
        String accessToken;
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                String fieldName = parser.getText();
                parser.nextToken();
                if(fieldName == 'access_token') {
                    accessToken =  parser.getText();
                }
            }
        }
        
        return '{"access_token":"'+accessToken+'"}';
    }
 
    global class Response{
        String status;
        String statusMsg;
        public Response(String status,String msg){
            this.status=status;
            this.statusMsg=msg;
        }
    }    
 
    

}
