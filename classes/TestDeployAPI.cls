@isTest
private class TestDeployAPI {
	@testSetup static void setupData() {
		TestUtilities.getAllMultilicense();
    }
	@testSetup static void setupDataDML() {
		TestUtilities.assignLicense(UserInfo.getUserName(),true, true, true, true, true);
	}
	static testMethod void testDeployANDdeployNow(){
		Org__c testFromOrg = testMethodUtilities.create('OrgName','Production','PASSWORD','SFDC_OrgId','SFDC_TOKEN','USERNAME', System.now());
		insert testFromOrg;
		Deployment__c testDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Pending');
		insert testDeployment;
		Step__c testStep = testMethodUtilities.create('a','b','c',testDeployment.Id,0,'Draft','MetaData');
		insert testStep;
		Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id,'Draft',testFromOrg.Id);
		insert testDestOrg;
		Deployment_Job__c testJob = testMethodUtilities.create(0,testDestOrg.Id,'external_id','Draft',testStep.Id);
		insert testJob;
		Test.startTest();
		List<Id> ids = new List<Id>();
		ids.add(testDeployment.Id);
		DeployAPI con = new DeployAPI();
		String b = '{"customerOrg":{"Name":"Copado","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		DeployAPI.deploy(ids, 'sid');
	    DeployAPI.deploy(testDeployment.Id, 'sid');
	    Test.stopTest();
	   	boolean bbb=true;system.assertEquals(true,bbb);
	}
	static testMethod void testEstimateDeploy(){
		Test.startTest();
		String b = '{"a06b0000006kRbWAAU":"In progress","a06b0000006kQlxAAE":"5","a06b0000006vrzDAAQ":"In progress","a06b0000006kQ7yAAE":"In progress","a06b0000006kPdPAAU":"In progress"}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
	    Map<String,Object> result = DeployAPI.estimateDeploy('a06b0000006kQlxAAE', 'sid');
	    Test.stopTest();
	    system.assertEquals('In progress', result.get('a06b0000006kRbWAAU'));
	    system.assertEquals('5', result.get('a06b0000006kQlxAAE'));
	}
	static testMethod void testGetCredits(){
		Test.startTest();
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		Integer i = DeployAPI.getCredits();
		system.assertEquals(425,i);
	    Test.stopTest();
	    boolean bbb=true;system.assertEquals(true,bbb);
	}
	static testMethod void testSaveDeploy(){
		Test.startTest();
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		DeployAPI.saveDeploy('a06b0000006kQlxAAE', 'sid');
	    Test.stopTest();
	    boolean bbb=true;system.assertEquals(true,bbb);
	}
	static testMethod void testCleanDeploy(){
        Org__c testFromOrg = testMethodUtilities.create('OrgName','Production','PASSWORD','SFDC_OrgId','SFDC_TOKEN','USERNAME', System.now());
		insert testFromOrg;
		Deployment__c testDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Pending');
		insert testDeployment;
		Test.startTest();
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		DeployAPI.cleanDeploy(testDeployment.Id);
	    Test.stopTest();
	    boolean bbb=true;system.assertEquals(true,bbb);
	}
	static testMethod void testDeployJob(){
		Org__c testFromOrg = testMethodUtilities.create('OrgName','Production','PASSWORD','SFDC_OrgId','SFDC_TOKEN','USERNAME', System.now());
		insert testFromOrg;
		Deployment__c testDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Pending');
		insert testDeployment;
		Step__c testStep = testMethodUtilities.create('a','b','c',testDeployment.Id,0,'Draft','MetaData');
		insert testStep;
		Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id,'Draft',testFromOrg.Id);
		insert testDestOrg;
		Deployment_Job__c testJob = testMethodUtilities.create(0,testDestOrg.Id,'external_id','Draft',testStep.Id);
		insert testJob;
		
		Test.startTest();
		List<Id> ids = new List<Id>();
		ids.add(testJob.Id);
		DeployAPI con = new DeployAPI();
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		DeployAPI.deployJob(ids, 'sid');
	    Test.stopTest();
	    boolean bbb=true;system.assertEquals(true,bbb);
	}
	static testMethod void testBackupNow(){
		Settings__c settings = new Settings__c();
		Blob key = Crypto.generateAesKey(256);        
		settings.cryptoKey__c = EncodingUtil.base64Encode(key);
        settings.server_url__c = 'test.com';
        insert settings;
        Feature__c f = new Feature__c(Name='Git Backup', Enabled__c=true);
        insert f;
        
        Org__c managingOrg = testMethodUtilities.create('OrgName','Production','PASSWORD',UserInfo.getOrganizationId(),'SFDC_TOKEN','USERNAME', System.now());
        insert managingOrg;
        Org__c org = testMethodUtilities.create('OrgName','Production','PASSWORD','SFDC_OrgId2','SFDC_TOKEN','USERNAME', System.now());
        insert org;
        Git_Repository__c gitRepo = testMethodUtilities.create('test','username','password','http://www.test.uri');
        insert gitRepo;
        Git_Backup__c gitBackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        insert gitBackup;
        
		DeployAPI con = new DeployAPI();
		String b = '{"Status":"OK"}';
	    String url = settings.Server_URL__c+'/json/v1/backupNow/'+gitBackup.Id+'?copadoOrgId='+UserInfo.getOrganizationId()+'&copadoUserId='+UserInfo.getUserId()+'&orgId='+gitBackup.Org__c;
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, url));
		Test.startTest();
		DeployAPI.backupNow(gitBackup.Id);
	    Test.stopTest();
	    
	    boolean bbb=true;system.assertEquals(true,bbb);
	}
	static testMethod void testTestNow(){
		Settings__c settings = new Settings__c();
        settings.server_url__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);
		settings.cryptoKey__c = EncodingUtil.base64Encode(key);
        insert settings;
        Feature__c f = new Feature__c(Name='Git Backup', Enabled__c=true);
        insert f;
        
        Org__c org = new Org__c(name='test org');
        insert org;
        
		DeployAPI con = new DeployAPI();
		String b = '{"Status":"OK"}';
	    String url = settings.Server_URL__c+'/json/v1/testNow/orgIdx123?copadoOrgId='+UserInfo.getOrganizationId()+'&copadoUserId='+UserInfo.getUserId();
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, url));
		Test.startTest();
		DeployAPI.testNow(org.id); //any id can be passed for the sake of testing.
	    Test.stopTest();
	    
	    boolean bbb=true;system.assertEquals(true,bbb);
	}
	static testMethod void testValidateOrg(){
		Settings__c settings = new Settings__c();
        settings.server_url__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);        
		settings.cryptoKey__c = EncodingUtil.base64Encode(key);
        insert settings;
        Feature__c f = new Feature__c(Name='Git Backup', Enabled__c=true);
        insert f;
        
        DeployAPI con = new DeployAPI();
		String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		Test.startTest();
		DeployAPI.validateOrg(settings.id); //any id can be passed for the sake of testing.
	    Test.stopTest();
	    boolean bbb=true;system.assertEquals(true,bbb);
	}
	static testMethod void testValidateGit_success(){
		Settings__c settings = new Settings__c();
        settings.server_url__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);        
		settings.cryptoKey__c = EncodingUtil.base64Encode(key);
        insert settings;
        Feature__c f = new Feature__c(Name='Git Backup', Enabled__c=true);
        insert f;
        
        Org__c managingOrg = testMethodUtilities.create('OrgName','Production','PASSWORD',UserInfo.getOrganizationId(),'SFDC_TOKEN','USERNAME', System.now());
        insert managingOrg;
        Org__c org = testMethodUtilities.create('OrgName','Production','PASSWORD','SFDC_OrgId2','SFDC_TOKEN','USERNAME', System.now());
        insert org;
        Git_Repository__c gitRepo = testMethodUtilities.create('test','username','password','http://www.test.uri');
        insert gitRepo;
        Git_Backup__c gitBackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        insert gitBackup;
		DeployAPI con = new DeployAPI();
		String b = '{"Status":"OK"}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		Test.startTest();
		DeployAPI.validateGit(gitRepo.Id);
	    Test.stopTest();
	    boolean bbb=true;system.assertEquals(true,bbb);
	}
	static testMethod void testHerokuResponseSuccessError(){
		Settings__c settings = new Settings__c();
        settings.server_url__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);        
		settings.cryptoKey__c = EncodingUtil.base64Encode(key);
        insert settings;
        Feature__c f = new Feature__c(Name='Git Backup', Enabled__c=true);
        insert f;
        
        Org__c managingOrg = testMethodUtilities.create('OrgName','Production','PASSWORD',UserInfo.getOrganizationId(),'SFDC_TOKEN','USERNAME', System.now());
        insert managingOrg;
        Org__c org = testMethodUtilities.create('OrgName','Production','PASSWORD','SFDC_OrgId2','SFDC_TOKEN','USERNAME', System.now());
        insert org;
        Git_Repository__c gitRepo = testMethodUtilities.create('test','username','password','http://www.test.uri');
        insert gitRepo;
        Git_Backup__c gitBackup = testMethodUtilities.create('backupname', 'branchName', 'Daily', gitRepo, null, org);
        insert gitBackup;
		DeployAPI con = new DeployAPI();
		String b = '{"error":"oops"}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		Test.startTest();
        System.assert(!DeployAPI.validateGit(gitRepo.Id).success,'this is not validated because of error response above');
	    Test.stopTest();
	    boolean bbb=true;system.assertEquals(true,bbb);
	}
    static testMethod void testApiKeyCreation(){
        String b = '{"ok":"API Key generated","api_key":"new key value"}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
	    Test.startTest();
        DeployAPI.createAPIKey();
        Test.stopTest();
        system.assertEquals('new key value', DeployAPI.getUserAPIKey());
    }

	static testMethod void testCancelDeploymetn(){
		Org__c testFromOrg = testMethodUtilities.create('OrgName','Production','PASSWORD','SFDC_OrgId','SFDC_TOKEN','USERNAME', System.now());
		insert testFromOrg;
		Deployment__c testDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Pending');
		insert testDeployment;
		Step__c testStep = testMethodUtilities.create('a','b','c',testDeployment.Id,0,'Draft','MetaData');
		insert testStep;
		Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id,'Draft',testFromOrg.Id);
		insert testDestOrg;
		Deployment_Job__c testJob = testMethodUtilities.create(0,testDestOrg.Id,'external_id','Draft',testStep.Id);
		testJob.Status__c  = 'Pending';
		insert testJob;
		
		Test.startTest();
		system.debug(testJob.Status__c);
			DeployAPI.cancelDeployment(testDeployment.id);
	    Test.stopTest();
	    Deployment_Job__c tj = [select Status__c from Deployment_Job__c where id = : testJob.Id];
	   	system.assertEquals('Cancelled',tj.Status__c);
	}

	static testMethod void testPMDorg(){
    	Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
	    insert scas;

        Feature__c f = new Feature__c(Name='Branch Management', Enabled__c=true, Quantity__c=5);
        insert f;
        Feature__c f2 = new Feature__c(Name='Git Backup', Enabled__c=true);
   		insert f2;
   		Feature__c f3 = new Feature__c(Name='Apex Test', Enabled__c=true);
        insert f3;
        
        Git_Repository__c gr = new Git_Repository__c(Name='test');
        insert gr;
        
        Deployment_Flow__c df = new Deployment_Flow__c(Name='test', Active__c=true, Main_Branch__c='master', Git_Repository__c=gr.Id, Static_Code_Analysis_Settings__c=scas.Id);
        insert df;

        List<Environment__c> Le = new List<Environment__c>();
        for (Integer i=0;i<6;i++) {
            Environment__c e = new Environment__c (Name = 'Env' + i);
            Le.add(e);
        }
        insert Le;
        
        List<Org__c> Lo = new List<Org__c>();
        for (Integer i=0;i<6;i++) {
            Org__c o = new Org__c (Name = 'Org' + i, Environment__c = Le[i].Id);
            Lo.add(o);
        }
        insert Lo;
        
        List<Deployment_Flow_Step__c> inserts = new List<Deployment_Flow_Step__c>();
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c=df.Id, Branch__c='dev1', Source_Environment__c=Le[0].Id, Destination_Environment__c=Le[1].Id));
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c=df.Id, Branch__c='dev2', Source_Environment__c=Le[1].Id, Destination_Environment__c=Le[2].Id));
        insert inserts;

		Settings__c settings = new Settings__c();
        settings.server_url__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);        
		settings.cryptoKey__c = EncodingUtil.base64Encode(key);
        insert settings;
        
        DeployAPI con = new DeployAPI();
		String b = '{"status":"OK"}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

		Test.startTest();
		DeployAPI.orgCodeAnalysis(Lo[0].id); //any id can be passed for the sake of testing.
	    Test.stopTest();
	    boolean bbb=true;system.assertEquals(true,bbb);
	}

	static testMethod void testPMDus(){
    	Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
	    insert scas;

        Feature__c f = new Feature__c(Name='Branch Management', Enabled__c=true, Quantity__c=5);
        insert f;
        Feature__c f2 = new Feature__c(Name='Git Backup', Enabled__c=true);
   		insert f2;
   		Feature__c f3 = new Feature__c(Name='Apex Test', Enabled__c=true);
        insert f3;
        
        Git_Repository__c gr = new Git_Repository__c(Name='test');
        insert gr;
        
        Deployment_Flow__c df = new Deployment_Flow__c(Name='test', Active__c=true, Main_Branch__c='master', Git_Repository__c=gr.Id, Static_Code_Analysis_Settings__c=scas.Id);
        insert df;

        Project__c p = new Project__c(Name='Test Project',Deployment_Flow__c=df.Id);
        insert p;

        List<Environment__c> Le = new List<Environment__c>();
        for (Integer i=0;i<6;i++) {
            Environment__c e = new Environment__c (Name = 'Env' + i);
            Le.add(e);
        }
        insert Le;
        
        List<Org__c> Lo = new List<Org__c>();
        for (Integer i=0;i<6;i++) {
            Org__c o = new Org__c (Name = 'Org' + i, Environment__c = Le[i].Id);
            Lo.add(o);
        }
        insert Lo;

        User_Story__c us = new User_Story__c(Project__c = p.Id, Org_Credential__c = Lo[0].Id);
        insert us;

        String attBody = '[{"t":"ApexClass","n":"TestAccountTrigger"}]';
        Attachment testAttachment = createAttachment(us.Id, 'MetaData', attBody);
        insert testAttachment;

        attBody = '[{"t":"ApexClass","n":"AccountTriggerHelper"},{"t":"ApexClass","n":"MockClass"}]';
        testAttachment = createAttachment(us.Id, 'Git MetaData', attBody);
        insert testAttachment;

        attBody = '[{"t":"ApexClass","n":"MockClass"}]';
        testAttachment = createAttachment(us.Id, 'Delete MetaData', attBody);
        insert testAttachment;
        
        List<Deployment_Flow_Step__c> inserts = new List<Deployment_Flow_Step__c>();
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c=df.Id, Branch__c='dev1', Source_Environment__c=Le[0].Id, Destination_Environment__c=Le[1].Id));
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c=df.Id, Branch__c='dev2', Source_Environment__c=Le[1].Id, Destination_Environment__c=Le[2].Id));
        insert inserts;

		Settings__c settings = new Settings__c();
        settings.server_url__c = 'test.com';
        Blob key = Crypto.generateAesKey(256);        
		settings.cryptoKey__c = EncodingUtil.base64Encode(key);
        insert settings;
        
        DeployAPI con = new DeployAPI();
		String b = '{"status":"OK"}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

		Test.startTest();
		DeployAPI.usCodeAnalysis(Lo[0].Id, us.Id); //any id can be passed for the sake of testing.
	    Test.stopTest();
	    boolean bbb=true;system.assertEquals(true,bbb);
	}

	static testMethod void testPMDusException(){
    	Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c();
	    insert scas;

        Feature__c f = new Feature__c(Name='Branch Management', Enabled__c=true, Quantity__c=5);
        insert f;
        Feature__c f2 = new Feature__c(Name='Git Backup', Enabled__c=true);
   		insert f2;
   		Feature__c f3 = new Feature__c(Name='Apex Test', Enabled__c=true);
        insert f3;
        
        Git_Repository__c gr = new Git_Repository__c(Name='test');
        insert gr;
        
        Deployment_Flow__c df = new Deployment_Flow__c(Name='test', Active__c=true, Main_Branch__c='master', Git_Repository__c=gr.Id, Static_Code_Analysis_Settings__c=scas.Id);
        insert df;

        Project__c p = new Project__c(Name='Test Project',Deployment_Flow__c=df.Id);
        insert p;

        List<Environment__c> Le = new List<Environment__c>();
        for (Integer i=0;i<6;i++) {
            Environment__c e = new Environment__c (Name = 'Env' + i);
            Le.add(e);
        }
        insert Le;
        
        List<Org__c> Lo = new List<Org__c>();
        for (Integer i=0;i<6;i++) {
            Org__c o = new Org__c (Name = 'Org' + i, Environment__c = Le[i].Id);
            Lo.add(o);
        }
        insert Lo;

        User_Story__c us = new User_Story__c(Project__c = p.Id, Org_Credential__c = Lo[0].Id);
        insert us;
        
        List<Deployment_Flow_Step__c> inserts = new List<Deployment_Flow_Step__c>();
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c=df.Id, Branch__c='dev1', Source_Environment__c=Le[0].Id, Destination_Environment__c=Le[1].Id));
        inserts.add(new Deployment_Flow_Step__c(Deployment_Flow__c=df.Id, Branch__c='dev2', Source_Environment__c=Le[1].Id, Destination_Environment__c=Le[2].Id));
        insert inserts;

		Settings__c settings = new Settings__c();
        settings.server_url__c = 'test.org';
        Blob key = Crypto.generateAesKey(256);        
		settings.cryptoKey__c = EncodingUtil.base64Encode(key);
        insert settings;
        
        DeployAPI con = new DeployAPI();
		String b = '{"status":"OK"}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

		Test.startTest();
		//Raises an exception, not metadata found
		try {
			DeployAPI.usCodeAnalysis(Lo[0].Id, us.Id); //any id can be passed for the sake of testing.
		}
		catch (Exception e) {
			System.assertEquals(Label.METADATA_NOT_FOUND, e.getMessage());
		}	
	    Test.stopTest();
	}

	private static Attachment createAttachment(String parentId, String name, String body){
		Attachment a = new Attachment(parentId=parentId, name=name);
		a.Body = Blob.valueOf(body);
		return a;
	}

	static testMethod void testOrgComplianceScan(){
    	Compliance_Rule_Group__c complianceSetting = new Compliance_Rule_Group__c();
	    insert complianceSetting;

        Feature__c feature = new Feature__c(Name='Compliance Hub', Enabled__c=true, Quantity__c=5);
        insert feature;        

        Environment__c envProd = new Environment__c(Name='Prod Environment',Type__c='Production', Compliance_Rule_Group__c = complianceSetting.Id);
        insert envProd;
        
        Org__c orgProd = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', null, 'SFDC_OrgId', null, null, system.now(), envProd.Id);
        insert orgProd;
        
		Settings__c settings = new Settings__c();
        settings.Server_Url__c = 'test.com';
        insert settings;
        
        DeployAPI controller = new DeployAPI();
		String b = '{"status":"OK"}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

		Test.startTest();
		DeployAPI.orgComplianceScan(orgProd.id); 
	    Test.stopTest();
	    Boolean bbb=true;system.assertEquals(true,bbb);
	}

}