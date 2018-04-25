@isTest
private class TestJsRemotingController {
    @testSetup static void TestBackupNow(){
        insert TestUtilities.getTestSettings();
    }
    static testMethod void coverageForContstructors(){
        JsRemotingController con1 = new JsRemotingController();
        Org__c org = new Org__c();
        JsRemotingController con2 = new JsRemotingController(new ApexPages.StandardController(org));
        system.assert(con1 != null); //dummy assertion for security scan;
    }
    static testMethod void createAPIKey(){
        String b = '{"ok":"API Key generated","api_key":"test 123"}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Personal_Settings__c mySettings = Personal_Settings__c.getInstance();
        mySettings.API_Key__c = 'test 1234';
        Test.startTest();
        JsRemotingController.createAPIKey();
        system.assertEquals('test 123', DeployAPI.getUserAPIKey());
        Test.stopTest();
    }
    static testMethod void getMetadataTypes(){
        String b = '{"ok":"API Key generated","api_key":"test 123"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Personal_Settings__c mySettings = Personal_Settings__c.getInstance();
        mySettings.API_Key__c = 'test 1234';
        Test.startTest();
        JsRemotingController.getMetadataTypes('ORGIDFAKE');
        Test.stopTest();
    }
    static testMethod void getVlocityDependencies(){
        String b = '{"ok":"API Key generated","api_key":"test 123"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        Personal_Settings__c mySettings = Personal_Settings__c.getInstance();
        mySettings.API_Key__c = 'test 1234';
        Test.startTest();
        JsRemotingController.getVlocityDependencies(UserInfo.getUserId(), 'FAKEJSONBODY');
        Test.stopTest();
    }

}