@isTest
private class TestPostInstallClass {
	@testSetup static void setupTestData(){
		TestUtilities.setTestSettingsEE();
	}
	static testMethod void testCleanInstall() {
		String b = '{"ok":"key registered","isSuccess":true,"isFinished":true}';
		Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		Test.startTest();
		PostInstallClass postinstall = new PostInstallClass();
		Test.testInstall(postinstall, null);

		testMethodUtilities.upsertOrgwideSettings();

		system.assertNotEquals(null, Settings__c.getOrgDefaults().CryptoKEY__c);
		Test.stopTest();
	}
	static testMethod void testUpgradeInstall() {
		Settings__c result = Settings__c.getOrgDefaults();
		Blob key = Crypto.generateAesKey(256);
		result.CryptoKEY__c = EncodingUtil.base64Encode(key);
		upsert result;
		system.assertEquals(EncodingUtil.base64Encode(key), result.CryptoKEY__c);
		Git_Repository__c g = new Git_Repository__c(name = 'g', Password__c = 'test');
		insert g;
		Personal_Settings__c s = new Personal_Settings__c(
		    Name = 'test',
		    API_Key__c = 'test'
		);
		insert s;
		String b = '{"ok":"key registered","isSuccess":true,"isFinished":true}';
		Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		Test.startTest();
		PostInstallClass postinstall = new PostInstallClass();
		Test.testInstall(postinstall, new Version(1, 0), false);

		system.assertNotEquals('test', [SELECT Password__c FROM Git_Repository__c WHERE Id = : g.Id LIMIT 1].Password__c);
		Test.stopTest();
	}

	static testMethod void testUpgradeInstallTwo() {
		Settings__c result = Settings__c.getOrgDefaults();
		Blob key = Crypto.generateAesKey(256);
		result.CryptoKEY__c = EncodingUtil.base64Encode(key);
		upsert result;
		system.assertEquals(EncodingUtil.base64Encode(key), result.CryptoKEY__c);
		Git_Repository__c g = new Git_Repository__c(name = 'g', Password__c = EncodingUtil.base64Encode(Blob.valueOf('test')));
		insert g;
		Personal_Settings__c s = new Personal_Settings__c(
		    Name = 'test',
		    API_Key__c = 'test'
		);
		insert s;
		String b = '{"ok":"key registered","isSuccess":true,"isFinished":true}';
		Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		Test.startTest();
		PostInstallClass postinstall = new PostInstallClass();
		Test.testInstall(postinstall, new Version(8, 40), false);

		system.assertNotEquals('test', [SELECT Password__c FROM Git_Repository__c WHERE Id = : g.Id LIMIT 1].Password__c);
		Test.stopTest();
	}
	static testMethod void testUpgradeInstallV9() {
		Settings__c result = Settings__c.getOrgDefaults();
		Blob key = Crypto.generateAesKey(256);
		result.CryptoKEY__c = EncodingUtil.base64Encode(key);
		upsert result;
		Blob deprecatedCryptoKey = EncodingUtil.base64Decode('TL9oaxsU41iBFFoM2eKNPQPQzSHb+pdta7GLCJRr0gg=');
		Blob data = Blob.valueOf('test');
        String tempApiKey = EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', deprecatedCryptoKey , data));
		system.assertEquals(EncodingUtil.base64Encode(key), result.CryptoKEY__c);
		Git_Repository__c g = new Git_Repository__c(name = 'g', Password__c = EncodingUtil.base64Encode(Blob.valueOf('test')));
		insert g;
		Personal_Settings__c s = new Personal_Settings__c(
		    Name = 'test',
		    API_Key__c = tempApiKey
		);
		insert s;
		ApexPages.StandardController sc = new ApexPages.StandardController(new External_CI_Setting__c());
		EditExternalCISetting handler = new EditExternalCISetting(sc);
		
		handler.externalCISetting.CI_Tool__c = 'Jenkins';
		handler.externalCISetting.API_Token__c = 'TestAPIToken';
		handler.externalCISetting.Endpoint__c = 'http://test-copado.copa.do:8080/';
		handler.externalCISetting.Password__c = 'testPW';
		handler.externalCISetting.Username__c = 'testUN';

		handler.save();
		String b = '{"ok":"key registered","isSuccess":true,"isFinished":true}';
		Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		Test.startTest();
		PostInstallClass postinstall = new PostInstallClass();
		Test.testInstall(postinstall, new Version(9, 0), false);
		
		system.assertNotEquals('test', [SELECT Password__c FROM Git_Repository__c WHERE Id = : g.Id LIMIT 1].Password__c);
		Test.stopTest();
	}
}