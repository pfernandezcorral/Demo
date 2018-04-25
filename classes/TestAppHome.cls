@isTest
private class TestAppHome {
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void testInitSuccess(){
        appHome con = new appHome();
        Test.startTest();
        String b = '{"transactions":[{"id":"402881a23e3c17b7013e3c17c8770000","date":"Apr 24, 2013 2:49:51 PM","customerOrgId":"'+userinfo.getorganizationid()+'","credits":-25,"type":"Free credits","userId":"'+userinfo.getuserid()+'","jobInfo":"New account free credits"},{"id":"402881a23e3c17b7013e3c17c8770000","date":"Apr 24, 2013 2:49:51 PM","customerOrgId":"'+userinfo.getorganizationid()+'","credits":25,"type":"Free credits","userId":"'+userinfo.getuserid()+'","jobInfo":"New account free credits"}],"customerOrg":{"Name":"Copado Ltd","orgId":"'+userinfo.getorganizationid()+'","autoRecharge":false,"credits":25,"id":1},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"'+userinfo.getorganizationid()+'","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"fl@copa.do","userFullName__is_set":true,"userFullName":"Federico Larsen","userId__is_set":true,"userId":"'+userinfo.getuserid()+'","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"fl@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        con.getTransactions();
        Test.stopTest();
        system.assertEquals(1, con.transactions.size());
    }
    
    static testMethod void testInitError2(){
        appHome con = new appHome();
        Test.startTest();
        String b = '{}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b,null));
        con.getTransactions();
        Test.stopTest();
        system.assert(testMethodUtilities.hasMessage('Attempt to de-reference a null object'));
    }
}