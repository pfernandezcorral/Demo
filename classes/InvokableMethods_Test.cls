@isTest
private class InvokableMethods_Test {
	@testSetup static void testSetup(){

        insert TestUtilities.getTestSettings();
        
		Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if(String.isBlank(ps.API_Key__c)){
            ps.API_Key__c = DeployAPI.encryptAPIKey('143sadfwet2341434');
            upsert ps;
        }
	}
	@isTest static void refreshOrgMetadataCacheTest(){
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

	    List<RefreshOrgMetadataCache.InvocableVariables> variableList = new List<RefreshOrgMetadataCache.InvocableVariables>();
	    RefreshOrgMetadataCache.InvocableVariables firstSet = new RefreshOrgMetadataCache.InvocableVariables();
	    firstSet.orgId = UserInfo.getUserId(); // mocking the id param
	    Boolean hasError = false;
	    try {
	    	variableList.add(firstSet);
	    } catch(Exception e) {
	    	hasError = true;
	    }
	    System.assertEquals(hasError, FALSE);
	    Test.startTest();
	    RefreshOrgMetadataCache.execute(variableList);
	    Test.stopTest();
	}
	@isTest static void calculateSnapshotDifferencesTest(){
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

	    List<CalculateSnapshotDifferences.InvocableVariables> variableList = new List<CalculateSnapshotDifferences.InvocableVariables>();
	    CalculateSnapshotDifferences.InvocableVariables firstSet = new CalculateSnapshotDifferences.InvocableVariables();
	    firstSet.snapshotDiffId = UserInfo.getUserId(); // mocking the id param
	    firstSet.deploy = FALSE;
	    Boolean hasError = false;
	    try {
	    	variableList.add(firstSet);
	    } catch(Exception e) {
	    	hasError = true;
	    }
	    System.assertEquals(hasError, FALSE);
	    Test.startTest();
	    CalculateSnapshotDifferences.execute(variableList);
	    Test.stopTest();
	}
	@isTest static void recalculateDeploymentFlowBranchStatuses(){
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

	    List<RecalculateDeploymentFlowBranchStatuses.InvocableVariables> variableList = new List<RecalculateDeploymentFlowBranchStatuses.InvocableVariables>();
	    RecalculateDeploymentFlowBranchStatuses.InvocableVariables firstSet = new RecalculateDeploymentFlowBranchStatuses.InvocableVariables();
	    firstSet.flowId = UserInfo.getUserId(); // mocking the id param
	    Boolean hasError = false;
	    try {
	    	variableList.add(firstSet);
	    } catch(Exception e) {
	    	hasError = true;
	    }
	    System.assertEquals(hasError, FALSE);
	    Test.startTest();
	    RecalculateDeploymentFlowBranchStatuses.execute(variableList);
	    Test.stopTest();
	}
	@isTest static void executeDeployment(){
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

	    List<ExecuteDeployment.InvocableVariables> variableList = new List<ExecuteDeployment.InvocableVariables>();
	    ExecuteDeployment.InvocableVariables firstSet = new ExecuteDeployment.InvocableVariables();
	    firstSet.depId = UserInfo.getUserId(); // mocking the id param
	    Boolean hasError = false;
	    try {
	    	variableList.add(firstSet);
	    } catch(Exception e) {
	    	hasError = true;
	    }
	    System.assertEquals(hasError, FALSE);
	    Test.startTest();
	    ExecuteDeployment.execute(variableList);
	    Test.stopTest();
	}
	@isTest static void takeGitSnapshot(){
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

	    List<TakeGitSnapshot.InvocableVariables> variableList = new List<TakeGitSnapshot.InvocableVariables>();
	    TakeGitSnapshot.InvocableVariables firstSet = new TakeGitSnapshot.InvocableVariables();
	    firstSet.snapshotId = UserInfo.getUserId(); // mocking the id param
	    Boolean hasError = false;
	    try {
	    	variableList.add(firstSet);
	    } catch(Exception e) {
	    	hasError = true;
	    }
	    System.assertEquals(hasError, FALSE);
	    Test.startTest();
	    TakeGitSnapshot.execute(variableList);
	    Test.stopTest();
	}
	@isTest static void runAllOrgApexTests(){
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

	    List<RunAllOrgApexTests.InvocableVariables> variableList = new List<RunAllOrgApexTests.InvocableVariables>();
	    RunAllOrgApexTests.InvocableVariables firstSet = new RunAllOrgApexTests.InvocableVariables();
	    firstSet.orgId = UserInfo.getUserId(); // mocking the id param
	    Boolean hasError = false;
	    try {
	    	variableList.add(firstSet);
	    } catch(Exception e) {
	    	hasError = true;
	    }
	    System.assertEquals(hasError, FALSE);
	    Test.startTest();
	    RunAllOrgApexTests.execute(variableList);
	    Test.stopTest();
	}
	@isTest static void runContinuousIntegration(){
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

	    List<RunContinuousIntegration.InvocableVariables> variableList = new List<RunContinuousIntegration.InvocableVariables>();
	    RunContinuousIntegration.InvocableVariables firstSet = new RunContinuousIntegration.InvocableVariables();
	    firstSet.ciId = UserInfo.getUserId(); // mocking the id param
	    Boolean hasError = false;
	    try {
	    	variableList.add(firstSet);
	    } catch(Exception e) {
	    	hasError = true;
	    }
	    System.assertEquals(hasError, FALSE);
	    Test.startTest();
	    RunContinuousIntegration.execute(variableList);
	    Test.stopTest();
	}
	@isTest static void runSeleniumTestGroup(){
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

	    List<RunSeleniumTestGroup.InvocableVariables> variableList = new List<RunSeleniumTestGroup.InvocableVariables>();
	    RunSeleniumTestGroup.InvocableVariables firstSet = new RunSeleniumTestGroup.InvocableVariables();
	    firstSet.groupId = UserInfo.getUserId(); // mocking the id param
	    Boolean hasError = false;
	    try {
	    	variableList.add(firstSet);
	    } catch(Exception e) {
	    	hasError = true;
	    }
	    System.assertEquals(hasError, FALSE);
	    Test.startTest();
	    RunSeleniumTestGroup.execute(variableList);
	    Test.stopTest();
	}
	@isTest static void runSeleniumTest(){
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

	    List<RunSeleniumTest.InvocableVariables> variableList = new List<RunSeleniumTest.InvocableVariables>();
	    RunSeleniumTest.InvocableVariables firstSet = new RunSeleniumTest.InvocableVariables();
	    firstSet.runId = UserInfo.getUserId(); // mocking the id param
	    Boolean hasError = false;
	    try {
	    	variableList.add(firstSet);
	    } catch(Exception e) {
	    	hasError = true;
	    }
	    System.assertEquals(hasError, FALSE);
	    Test.startTest();
	    RunSeleniumTest.execute(variableList);
	    Test.stopTest();
	}

	@isTest static void recalculateBranchStatus(){
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
		Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

		List<RecalculateBranchStatus.InvocableVariables> variableList = new List<RecalculateBranchStatus.InvocableVariables>();
		RecalculateBranchStatus.InvocableVariables firstSet = new RecalculateBranchStatus.InvocableVariables();
		firstSet.flowId = UserInfo.getUserId(); // mocking the id param
		firstSet.branchName = 'dev';
		Boolean hasError = false;
		try {
			variableList.add(firstSet);
		} catch(Exception e) {
			hasError = true;
		}
		System.assertEquals(hasError, FALSE);
		Test.startTest();
        RecalculateBranchStatus.execute(variableList);
		Test.stopTest();
	}
	@isTest static void userStoryCommitFiles(){
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
		Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

		List<UserStoryCommitFiles.InvocableVariables> variableList = new List<UserStoryCommitFiles.InvocableVariables>();
		UserStoryCommitFiles.InvocableVariables firstSet = new UserStoryCommitFiles.InvocableVariables();
		firstSet.userStoryId = UserInfo.getUserId(); // mocking the id param
		firstSet.commitMessage = 'TEST';
		firstSet.jsonBody = '[{}]';
		Boolean hasError = false;
		try {
			variableList.add(firstSet);
		} catch(Exception e) {
			hasError = true;
		}
		System.assertEquals(hasError, FALSE);
		Test.startTest();
		UserStoryCommitFiles.execute(variableList);
		Test.stopTest();
	}
	@isTest static void deployPromotion(){
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
		Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

		List<RunDeployPromotion.InvocableVariables> variableList = new List<RunDeployPromotion.InvocableVariables>();
		RunDeployPromotion.InvocableVariables firstSet = new RunDeployPromotion.InvocableVariables();
		firstSet.promotionId = UserInfo.getUserId(); // mocking the id param
		firstSet.checkOnly = true;
		firstSet.testLevel = 'Run All Tests';
		firstSet.deploymentName = 'My test deployment';
		Boolean hasError = false;
		try {
			variableList.add(firstSet);
		} catch(Exception e) {
			hasError = true;
		}
		System.assertEquals(hasError, FALSE);
		Test.startTest();
		RunDeployPromotion.execute(variableList);
		Test.stopTest();
	}
	@isTest static void orgCompliance(){
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
		Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

		List<RunOrgComplianceScan.InvocableVariables> variableList = new List<RunOrgComplianceScan.InvocableVariables>();
		RunOrgComplianceScan.InvocableVariables firstSet = new RunOrgComplianceScan.InvocableVariables();
		firstSet.orgId = UserInfo.getUserId(); // mocking the id param
		Boolean hasError = false;
		try {
			variableList.add(firstSet);
		} catch(Exception e) {
			hasError = true;
		}
		System.assertEquals(hasError, FALSE);
		Test.startTest();
		RunOrgComplianceScan.execute(variableList);
		Test.stopTest();
	}
    @isTest static void snapshotCompliance(){
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<RunSnapshotComplianceScan.InvocableVariables> variableList = new List<RunSnapshotComplianceScan.InvocableVariables>();
        RunSnapshotComplianceScan.InvocableVariables firstSet = new RunSnapshotComplianceScan.InvocableVariables();
        firstSet.snapId = UserInfo.getUserId(); // mocking the id param
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RunSnapshotComplianceScan.execute(variableList);
        Test.stopTest();
    }
    @isTest static void storyCompliance(){
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        List<RunUserStoryComplianceScan.InvocableVariables> variableList = new List<RunUserStoryComplianceScan.InvocableVariables>();
        RunUserStoryComplianceScan.InvocableVariables firstSet = new RunUserStoryComplianceScan.InvocableVariables();
        firstSet.storyId = UserInfo.getUserId(); // mocking the id param
        firstSet.repoId = UserInfo.getUserId(); // mocking the id param
        firstSet.branch = 'dev';
        Boolean hasError = false;
        try {
            variableList.add(firstSet);
        } catch(Exception e) {
            hasError = true;
        }
        System.assertEquals(hasError, FALSE);
        Test.startTest();
        RunUserStoryComplianceScan.execute(variableList);
        Test.stopTest();
    }
}