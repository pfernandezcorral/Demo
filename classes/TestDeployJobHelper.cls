@isTest
private class TestDeployJobHelper {
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
    @isTest
    public static void doTest() {
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c testOrg = testMethodUtilities.create('OrgTestName', 'Production', 'PASSWORD', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testOrg;
        Deployment__c d = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg.Id, 'Deploy now', 'Pending');
        insert d;
        Destination_Org__c o = testMethodUtilities.create(d.id, 'Pending', testOrg.Id);
        insert o;
        Step__c s = testMethodUtilities.create('Step 1', 'attId', 'JSONString', d.Id, 0, 'Pending', 'MetaData');
        insert s;
        System.assertEquals(1, [select count() from Deployment_Job__c where step__c = :s.id and destination_org__c = :o.id]);
        Destination_Org__c o2 = testMethodUtilities.create(d.id, 'Pending', testOrg.Id);
        insert o2;
        System.assertEquals(1, [select count() from Deployment_Job__c where step__c = :s.id and destination_org__c = :o2.id]);
        System.assertEquals(2, [select count() from Deployment_Job__c where step__c = :s.id]);

        delete o;
        System.assertEquals(1, [select count() from Deployment_Job__c where step__c = :s.id and destination_org__c = :o2.id]);
        System.assertEquals(1, [select count() from Deployment_Job__c where step__c = :s.id]);
    }

    @isTest
    public static void testNextStep() {
        testMethodUtilities.upsertOrgwideSettings();

        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c testOrg = testMethodUtilities.create('OrgName', 'Production', 'PASSWORD', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testOrg;
        Deployment__c d = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg.Id, 'Deploy now', 'In progress');
        insert d;
        Destination_Org__c o = testMethodUtilities.create(d.id, 'Pending', testOrg.Id);
        insert o;
        String dataJson = '{"Perform_in_Destination_Orgs":true,"Perform_in_Source_Org":false,"Task_Description":"","Task_Owner":"';
               dataJson += UserInfo.getUserId();
               dataJson += '","Notify_Task_Owner":"Chatter and Email"}';
        Step__c s = testMethodUtilities.create('Step 1', 'attId', dataJson, d.Id, 1, 'Pending', 'Manual Task');
        insert s;
        Step__c s2 = testMethodUtilities.create('Step 2', 'attId', 'JSONString', d.Id, 2, 'Pending', 'MetaData');
        insert s2;
        Destination_Org__c o2 = testMethodUtilities.create(d.id, 'Pending', testOrg.Id);
        insert o2;

        Deployment_Job__c dj11 = [select id, status__c from Deployment_Job__c where step__c = :s.id and destination_org__c = :o.id];
        System.assertEquals('Pending', dj11.Status__c);
        dj11.Status__c = 'Success';
        dj11.Deployed__c = 100;
        update dj11;
        system.assertEquals('In progress', [select status__c from step__c where id = :s.id].status__c);

        system.assertEquals('In progress', [select status__c from Deployment__c where id = :d.id].status__c);
    }
    @isTest
    public static void testNextStep2() {
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c testOrg = testMethodUtilities.create('OrgName', 'Production', 'PASSWORD', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testOrg;
        Deployment__c d = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg.Id, 'Deploy now', 'In progress');
        insert d;
        Destination_Org__c o = testMethodUtilities.create(d.id, 'Pending', testOrg.Id);
        insert o;
        Step__c s = testMethodUtilities.create('Step 1', 'attId', 'JSONString', d.Id, 1, 'Pending', 'MetaData');
        insert s;
        Step__c s2 = testMethodUtilities.create('Step 2', 'attId', 'JSONString', d.Id, 2, 'Pending', 'MetaData');
        insert s2;
        Destination_Org__c o2 = testMethodUtilities.create(d.id, 'Pending', testOrg.Id);
        insert o2;
        Test.startTest();
        Deployment_Job__c dj11 = [select id, status__c from Deployment_Job__c where step__c = :s.id and destination_org__c = :o.id];
        System.assertEquals('Pending', dj11.Status__c);
        dj11.Status__c = 'Failed';
        dj11.Deployed__c = 0;
        update dj11;
        system.assertEquals('In progress', [select status__c from step__c where id = :s.id].status__c);

        system.assertEquals('In progress', [select status__c from Deployment__c where id = :d.id].status__c);

        Deployment_Job__c dj12 = [select id, status__c from Deployment_Job__c where step__c = :s.id and destination_org__c = :o2.id];
        System.assertEquals('Pending', dj12.Status__c);
        dj12.Status__c = 'Failed';
        dj12.Deployed__c = 0;
        update dj12;
        system.assertEquals('Completed with Errors', [select status__c from step__c where id = :s.id].status__c);

        system.assertEquals('Completed with Errors', [select status__c from Deployment__c where id = :d.id].status__c);

        Deployment_Job__c dj21 = [select id, status__c from Deployment_Job__c where step__c = :s2.id and destination_org__c = :o.id];
        System.assertEquals('Pending', dj21.Status__c);
        system.assertEquals('Completed with Errors', [select status__c from step__c where id = :s.id].status__c);

        Deployment_Job__c dj22 = [select id, status__c from Deployment_Job__c where step__c = :s2.id and destination_org__c = :o2.id];
        System.assertEquals('Pending', dj22.Status__c);
        system.assertEquals('Pending', [select status__c from step__c where id = :s2.id].status__c);
        Test.stopTest();
    }
    @isTest
    public static void testNextStep3() {
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c testOrg = testMethodUtilities.create('OrgName', 'Production', 'PASSWORD', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testOrg;
        Deployment__c d = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg.Id, 'Deploy now', 'In progress');
        insert d;
        Destination_Org__c o = testMethodUtilities.create(d.id, 'Pending', testOrg.Id);
        insert o;
        Step__c s = testMethodUtilities.create('Step 1', 'attId', 'JSONString', d.Id, 1, 'Pending', 'MetaData');
        insert s;
        Destination_Org__c o2 = testMethodUtilities.create(d.id, 'Pending', testOrg.Id);
        insert o2;

        Deployment_Job__c dj11 = [select id, status__c from Deployment_Job__c where step__c = :s.id and destination_org__c = :o.id];
        System.assertEquals('Pending', dj11.Status__c);
        dj11.Status__c = 'Failed';
        dj11.Deployed__c = 0;
        update dj11;
        system.assertEquals('In progress', [select status__c from step__c where id = :s.id].status__c);
        system.assertEquals('In progress', [select status__c from Deployment__c where id = :d.id].status__c);
        system.assertEquals('Completed with Errors', [select status__c from Destination_Org__c where id = :o.id].status__c);

        Deployment_Job__c dj12 = [select id, status__c from Deployment_Job__c where step__c = :s.id and destination_org__c = :o2.id];
        System.assertEquals('Pending', dj12.Status__c);
        dj12.Status__c = 'Success';
        dj12.Deployed__c = 100;
        update dj12;
        system.assertEquals('Completed with Errors', [select status__c from step__c where id = :s.id].status__c);
        system.assertEquals('Completed Successfully', [select status__c from Destination_Org__c where id = :o2.id].status__c);
        system.assertEquals('Completed with Errors', [select status__c from Deployment__c where id = :d.id].status__c);
    }
}