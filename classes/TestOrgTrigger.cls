@isTest
private class TestOrgTrigger {
    @testSetup static void setupTestData(){
        insert TestUtilities.getTestSettings();
    }
    static testMethod void test_OrgTrigger() {
        BatchHelper.enforceScheduler();
        CronJobDetail cjd = [select id from CronJobDetail where Name ='Copado' and JobType='7' limit 1];
    	if(BatchHelper.isCopadoScheduled()){
    		System.abortJob([select id from CronTrigger where CronJobDetailId =:cjd.Id limit 1].Id);
    	}
	    System.assertEquals(false, BatchHelper.isCopadoScheduled());
        
        Org__c testOrg = testMethodUtilities.create('OrgName2','Sandbox','PASSWORD','SFDC_OrgId2','SFDC_TOKEN','USERNAME', System.now());
	    testOrg.Test_Frequency__c = 'Daily';
	    insert testOrg;
        
        System.assertEquals(true, BatchHelper.isCopadoScheduled());
    }
    static testMethod void test_environmentCreation(){
        Org__c testOrg = testMethodUtilities.create('OrgName2','Sandbox','PASSWORD','null','SFDC_TOKEN','USERNAME', null);
	    insert testOrg;
        
        testOrg.SFDC_Org_Id__c = '000000000000000000_100000000000000001';
        //testORg.validated_Date__c = system.now();
        update testOrg;
        
        List<Environment__c> results_envs = [select Id, Name, Org_ID__c from Environment__c where Org_ID__c='000000000000000000'];
        system.assertEquals(1, results_envs.size());
        List<Org__c> results_orgs = [select Id, Environment__c, SFDC_Org_ID__c from Org__c];
        system.assertEquals(results_envs[0].Id, results_orgs[0].Environment__c);
    }
}