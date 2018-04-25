@isTest
private class TestEditOrg {
	@testSetup static void setupData() {
		TestUtilities.enableLicenses(2, 0, 0, 0, 1);
	}
	@testSetup static void setupTestDataDML(){
        TestUtilities.insertUser('user1-TestEditOrg@test-copado.org','System Administrator');
        TestUtilities.assignLicense('user1-TestEditOrg@test-copado.org', true, false, false, false, true);
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
    }
	static testMethod void testSave() {
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        
		Org__c o = new Org__c(name='test',metadata_types__c = 'ApexPage,ApexClass');
		insert o; 

		EditOrg cont = new EditOrg(new ApexPages.StandardController(o));
		try{
			cont.save();
		}
		catch(Exception e){}
	}
    static testMethod void testGetMetadataTypes() {
        String b = '["ApexPage","ApexClass"]';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        
		Org__c o = new Org__c(name='test',metadata_types__c = 'ApexPage,ApexClass');
		insert o; 
		Test.startTest();        
		EditOrg cont = new EditOrg(new ApexPages.StandardController(o));
        Integer actual = cont.getMetadataTypes().size();
        Test.stopTest();
		System.assertEquals(2, actual);
	}
    static testMethod void testValidateOrg() {
        Org__c o = new Org__c(name='test',metadata_types__c = 'ApexPage,ApexClass');
        insert o;

        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        EditOrg cont = new EditOrg(new ApexPages.StandardController(o));
        cont.validate();
        system.assertEquals(true, testMethodUtilities.hasMessage(Label.ADD_AUTHENTICATION));
        o.oauth_signature__c = 'test';
        update o;


        try{
            cont.validate();
            system.debug('@@@@@@ '+ApexPages.getMessages());
            system.assertEquals(true, testMethodUtilities.hasMessage(Label.OK_CREDENTIALS));
        }
        catch(Exception e){}


        o.Test_Frequency__c = 'Daily';
        update o;

        Test.startTest();

        b = '{"customerOrg":{"Name":"Copado Ltd 2","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        EditOrg cont2 = new EditOrg(new ApexPages.StandardController(o));
        cont2.validate();

        System.assertEquals(true, testMethodUtilities.hasMessage(Label.WRONG_CREDENTIALS));

        Test.stopTest();
    }
    static testMethod void testOauthUrl(){
        Org__c o = new Org__c(name='test',metadata_types__c = 'ApexPage,ApexClass');
		insert o;

		EditOrg cont = new EditOrg(new ApexPages.StandardController(o));
		Test.startTest();
        
		try{
			PageReference pageRef = cont.doOauth();
            system.assert(pageRef.getUrl().contains('Authorize'));
		}
		catch(Exception e){}
        Test.stopTest();
    }
    static testMethod void testPasswordParameter() {
        Org__c o = new Org__c(name='test',metadata_types__c = 'ApexPage,ApexClass');
		insert o; 

		EditOrg cont = new EditOrg(new ApexPages.StandardController(o));

		Test.startTest();
        
		try{
			PageReference pageRef = cont.addUserPass();
            system.assert(pageRef.getUrl().contains('showUserPass=true'));
		}
		catch(Exception e){}
        Test.stopTest();
        cont.isLicenseEnabled();
	}
	static testMethod void testOrgCodeAnalysis() {
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		Org__c o = new Org__c(name='test',metadata_types__c = 'ApexPage,ApexClass', Org_Type__c = 'Production/Developer');
		insert o; 
	
		Test.startTest();
		EditOrg cont = new EditOrg(new ApexPages.StandardController(o));
        cont.orgCodeAnalysis();
		cont.validate();
        system.assert(testMethodUtilities.hasMessage(Label.ADD_AUTHENTICATION)); //No Oa
        o.oauth_signature__c = 'test';
        update o; 
        
        try {
            cont.validate();
            system.debug('@@@@@@ '+ApexPages.getMessages());
            cont.orgCodeAnalysis();
            System.assert(testMethodUtilities.hasMessage(Label.STATIC_CODE_ANALYSIS_REQUESTED));
		}
		catch(Exception e) {}
        Test.stopTest();
	}
	
	static testMethod void testOrgComplianceScan() {
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
	    b = '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"'+UserInfo.getOrganizationId()+'","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Compliance_Rule_Group__c complianceSetting = new Compliance_Rule_Group__c();
	    insert complianceSetting;

        Environment__c envProd = new Environment__c(Name='Prod Environment',Type__c='Production', Compliance_Rule_Group__c = complianceSetting.Id);
        insert envProd;

		Org__c org = new Org__c(name='test',metadata_types__c = 'Layout,Profile,PermissionSet', Environment__c = envProd.Id);
		insert org;
	
		Test.startTest();
		PageReference pref = Page.EditOrg;
        Test.setCurrentPage(pref);		

        EditOrg ext = new EditOrg(new ApexPages.StandardController(org));
		ext.validate();
	    System.debug('@@@@@@ '+ApexPages.getMessages());
	    ext.orgComplianceScan();
        System.assertEquals(true, testMethodUtilities.hasMessage(Label.CCH_LICENSE_NOT_ENABLED));

        List<User> users = [SELECT Id FROM User WHERE Username ='user1-TestEditOrg@test-copado.org'];
        System.runAs(users[0]){
	        EditOrg ext2 = new EditOrg(new ApexPages.StandardController(org));
	        ext2.validate();
	        System.debug('@@@@@@ '+ApexPages.getMessages());
	        ext2.orgComplianceScan();
	        System.assertEquals(true, testMethodUtilities.hasMessage(Label.COMPLIANCE_SCAN_REQUESTED));
	    }
        Test.stopTest();
	}

}