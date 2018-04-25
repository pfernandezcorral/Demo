@isTest
private class TestGitBackupTrigger {
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void test_OrgTrigger() {
        BatchHelper.enforceScheduler();
        CronJobDetail cjd = [select id from CronJobDetail where Name ='Copado' and JobType='7' limit 1];
    	if(BatchHelper.isCopadoScheduled()){
    		System.abortJob([select id from CronTrigger where CronJobDetailId =:cjd.Id limit 1].Id);
    	}
	    System.assertEquals(false, BatchHelper.isCopadoScheduled());

        Org__c org = testMethodUtilities.create('OrgName','Production','PASSWORD','SFDC_OrgId2','SFDC_TOKEN','USERNAME', System.now());
        insert org;
        update org;
        Git_Repository__c gitRepo = testMethodUtilities.create('test','username','password','http://www.test.uri');
        insert gitRepo;
        update gitRepo;
        Git_Backup__c gitBackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        insert gitBackup;
        update gitBackup;
        System.assertEquals(true,FeatureHelper.isFeatureEnabled('Git Backup'));
        System.assertEquals(true, BatchHelper.isCopadoScheduled());

        /*

        //TODO: this must be refactored or separated on another test class without lics


        Test.startTest();
        TestUtilities.exceedCopadoLicenses();
        try {
            update gitBackup;
            System.assert(false,'this must fail');
        } catch(Exception e){
            System.assert(true, e.getMessage().contains(Label.LICENSES_EXCEEDED));
        }
        TestUtilities.enableLicenses(2, 2, 2);

        try {
            update gitBackup;
            System.assert(false,'this must fail');
        } catch(Exception e){
            System.assert(true, e.getMessage().contains(Label.FEATURE_NOT_SUPPORTED + ': Git Backup'));
        }
        Test.stopTest();
        */

    }
}