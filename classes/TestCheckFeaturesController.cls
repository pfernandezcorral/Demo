@isTest
private class TestCheckFeaturesController{
	@testSetup static void setupTestData(){
		TestUtilities.setTestSettingsEE();
	}
	static testMethod void testCheckFeatures(){
        
        String b = '{"features":[{"feature":"myname","enabled":true,"expirationDate":null}]}';
        //String b = '{"ok":"Git validated"}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        
		Test.startTest();
		CheckFeaturesController.checkFeatures();
		Test.stopTest();

	}

	static testMethod void testCheckSetup(){
        
        Test.startTest();
        
		Boolean exists = CheckFeaturesController.checkSetup();
		System.assertEquals(false, exists);

		Org__c o = new Org__c(
			name = 'test', 
			SFDC_Org_ID__c = Userinfo.getOrganizationId()+'_'+Userinfo.getUserId(),
			Validated_Date__c = Datetime.now()
		);
		insert o;

		exists = CheckFeaturesController.checkSetup();
		System.assertEquals(true, exists);

		Test.stopTest();

	}
	/*
	 * These tests test the code on the FeatureHelper class.  
	 * As a test class does not exist for it, we will test the code here and later
	 * move it into the new test class so we can push this out to customers.		
	*/
    static testMethod void testGitBackupEnabled_CopadoUser(){
		System.assertEquals(true, FeatureHelper.isFeatureEnabled('Git Backup'));
    }
}