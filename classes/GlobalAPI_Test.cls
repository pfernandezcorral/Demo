@isTest
private class GlobalAPI_Test {
	@testSetup static void setupData() {
		FeatureManagement.setPackageIntegerValue('EE_Licenses_Enabled',1);
		FeatureManagement.setPackageIntegerValue('CCM_Licenses_Enabled',1);
		FeatureManagement.setPackageIntegerValue('CST_Licenses_Enabled',1);
		FeatureManagement.setPackageIntegerValue('CAD_Licenses_Enabled',1);
		FeatureManagement.setPackageIntegerValue('CCH_Licenses_Enabled',1);
    }
	@isTest static void testMethodOne() {
		upsert TestUtilities.getTestSettings();
		Test.startTest();
		GlobalAPI.UserLicense myLicense = new GlobalAPI.UserLicense(UserInfo.getUserId(),true,true,true,true,true);
		
		GlobalAPI gapi = new GlobalAPI();
		GlobalAPI.CopadoLicenses licenses = gapi.getLicenseInformation();
		List<GlobalAPI.UserLicense> licenseList = gapi.listCopadoLicenses();
		System.debug('*** licenseList: ' + licenseList);
		System.assertEquals(0,licenseList.size());
		String res = gapi.upsertCopadoLicense(UserInfo.getUserId(),myLicense);
		System.assertEquals('INSERTED',res);
		String res2 = gapi.upsertCopadoLicense(UserInfo.getUserId(),myLicense);
		System.assertEquals('UPDATED',res2);
		gapi.deleteCopadoLicense(UserInfo.getUserId());
		Test.stopTest();
	}
}