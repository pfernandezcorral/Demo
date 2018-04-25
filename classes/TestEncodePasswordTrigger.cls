@isTest
private class TestEncodePasswordTrigger {
    @testSetup static void setupData() {
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void myUnitTest() {
        Org__c org = testMethodUtilities.create('OrgName','Production','PASSWORD','SFDC_OrgId2','SFDC_TOKEN','USERNAME', System.now());
        insert org;
        Org__c resultOrg = [select Id, Password__c from Org__c where Id=:org.Id limit 1];
        system.assert(org.password__c != resultOrg.password__c);
    }
}