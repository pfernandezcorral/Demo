public with sharing class SeleniumTestGroupExtension {
    Selenium_Test_Group__c grp;
    public SeleniumTestGroupExtension (ApexPages.StandardController stdController){
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) stdController.addFields(new List<String>(Schema.SObjectType.Selenium_Test_Group__c.fields.getMap().keySet()));
        this.grp = (Selenium_Test_Group__c)stdController.getRecord();
    }
    public PageReference runGroup(){
        try{
        	WebhookAPI.runSeleniumTestGroup(grp.Id, DeployAPI.getUserAPIKey());    
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
		return new PageReference('/'+grp.Id);
    }
}