public with sharing class creditsCompController {
	
	public String buyCreditsUrl {get;set;}
	public String manageSubscriptionUrl {get;set;}
	public String autoRechargeUrl {get;set;}
	public String creditBalance{get;set;}
    public String minutesBalance {get;set;}
	public boolean isValid {get;set;}
	public boolean autoRechargeEnabled {get;set;}
	
	public boolean showError {get;set;}
	public String errorMessage {get;set;}
	
	public creditsCompController(){
		showError = false;
		autoRechargeEnabled = false;
		errorMessage = '';
		isValid = true;
		getCredits();
	}
	public void getCredits(){
		try{
			Http h = new Http();
	    	HttpRequest req = new HttpRequest();
	    	DeployAPI.setAuthHeaders(req);//to authenticate agains heroku servers
	    	req.setEndpoint(settings.Server_URL);
	    	req.setMethod('GET');
	    	system.debug(req);
	    	HttpResponse res = h.send(req);
	    	system.debug(res);
	    	system.debug(res.getBody());
            if(res.getStatusCode()==200){
            	Map<String, Object> fullMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
				Map<String, Object> orgMap = (Map<String, Object>)fullMap.get('customerOrg');	
                creditBalance = ''+(Integer)orgMap.get('credits');
                minutesBalance = ''+(Integer)orgMap.get('minutes');
                autoRechargeEnabled = (boolean)orgMap.get('autoRecharge');
                buyCreditsUrl = settings.Copado_Site+'/buyCredits?lang='+Userinfo.getLanguage()+'&userId='+userinfo.getUserId()+'&orgId='+Userinfo.getOrganizationId();
                autoRechargeUrl = settings.Copado_Site+'/autoRecharge?lang='+Userinfo.getLanguage()+'&userId='+userinfo.getUserId()+'&orgId='+Userinfo.getOrganizationId();
                manageSubscriptionUrl = settings.Server_URL+'/subscription/manage';
            }
            else{
                showError = true;
				errorMessage = res.getStatusCode() + (res.getStatus() != null ? +' - '+ res.getStatus() : '');
            }
                
		}
		catch(Exception ex){
			showError = true;
			errorMessage = ''+ex;
		}
	}

	public PageReference getLicenseManagerReference(){
		PageReference redirectPage = Page.LicenseManager;
		redirectPage.setRedirect(true);
		return redirectPage;
	}
}