## Sample code for using the Refresh Token Apex REST service

```
	public static void accessToken() throws JsonGenerationException, JsonMappingException, IOException{
		ApiSession apiSession = Auth.authenticate(new ApiConfig().setUsername(System.getenv("SFDC_USERNAME"))
															  .setPassword(System.getenv("SFDC_PASSWORD")));
		Map<String,Object> postParams = new HashMap<String,Object>();
		
		postParams.put("code",params.get("code"));
		postParams.put("client_id", FORCE_OAUTH_KEY);
		postParams.put("client_secret", FORCE_OAUTH_SECRET);
		postParams.put("redirect_uri", APP_URI+"/_auth");
		String orgType = params.get("state").endsWith("sandbox") ? "sandbox":"production";
		postParams.put("orgType",orgType);
		ObjectMapper mapper = new ObjectMapper();
		String jsonString = mapper.writeValueAsString(postParams);
		logger.info(String.format("[dv-refresh-token] Calling Apex Web Service to store refreshToken, postParams=%s",postParams));
		WS.HttpResponse response    = WS.url("https://na9-api.salesforce.com/services/apexrest/dotversion/refreshToken")
				 			  			.setHeader("Authorization","OAuth "+apiSession.getAccessToken())
				 			  			.setHeader("Content-Type", "application/json; charset=UTF-8")
				 			  			.setHeader("Accept", "application/json")
				 			  			.body(jsonString)
				 			  			.post();
		String respStr = response.getString();
		respStr = StringEscapeUtils.unescapeJava(respStr);
		logger.info(String.format("[dv-refresh-token] Response = %s",respStr));
		Map<String, String> values = mapper.readValue(respStr.substring(1,respStr.length()-1), 
													  new TypeReference<Map<String, String>>() {});

		session.put("username", values.get("username"));
		session.put("org_id",values.get("org_id"));
		System.out.println(">>>>>>>>>>>> state="+params.get("state"));
		if(!params.get("state").contains("/orgs")){
			redirect("/org/"+values.get("org_id"));	
		}else{
			redirect(params.get("state"));
		}
		
}
```	
