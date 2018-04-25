@isTest
private class TestDeploymentExt {
    @testSetup 
    static void setupData() {
        TestUtilities.enableLicenses(2,2,0);
    }
    private static void setDataDML(){
        TestUtilities.insertUser('user1-TestDeploymentExt@test-copado.org','System Administrator');
        TestUtilities.assignLicense('user1-TestDeploymentExt@test-copado.org', false, true, false);
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false);
    }
	@isTest static void testController() {
        setDataDML();
        List<Org__c> orgs = new List<Org__c>();
		Org__c testFromOrg = TestMethodUtilities.create('OrgName','Production','PASSWORD','SFDC_OrgId','SFDC_TOKEN','USERNAME', System.now());
		orgs.add( testFromOrg );
        Org__c testToOrg = TestMethodUtilities.create('OrgName2','Production','PASSWORD2','SFDC_OrgId2','SFDC_TOKEN2','USERNAME', System.now());
        Org__c testToOrg2 = TestMethodUtilities.create('OrgName3','Production','PASSWORD2','SFDC_OrgId3','SFDC_TOKEN3','USERNAME', System.now());
        Org__c testToOrg3 = TestMethodUtilities.create('OrgName4','Production','PASSWORD2','SFDC_OrgId4','SFDC_TOKEN4','USERNAME', System.now());
        Org__c testToOrg4 = TestMethodUtilities.create('OrgName5','Production','PASSWORD2','SFDC_OrgId5','SFDC_TOKEN5','USERNAME', System.now());
        Org__c testToOrg5 = TestMethodUtilities.create('OrgName6','Production','PASSWORD2','SFDC_OrgId6','SFDC_TOKEN6','USERNAME', System.now());
        orgs.add( testToOrg );
        orgs.add( testToOrg2 );
        orgs.add( testToOrg3 );
        orgs.add( testToOrg4 );
        orgs.add( testToOrg5 );

        insert orgs;

		Deployment__c testDeployment = TestMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Scheduled');
        insert testDeployment;
        List<Step__c> steps = new List<Step__c>();
		Step__c testStep = TestMethodUtilities.create('Step 1','attId','JSONString',testDeployment.Id,0,'Not started','MetaData');
        steps.add(testStep);
        for(Integer i = 0; i<199; i++){
            Step__c temp = TestMethodUtilities.create('Step '+i,'attId','JSONString',testDeployment.Id,0,'Not started','Manual Task');
             steps.add(temp);
        }
        insert steps;
        List<Destination_Org__c> destinationOrgs = new List<Destination_Org__c>();

		Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id,'Draft',testFromOrg.Id);
        destinationOrgs.add(testDestOrg);

        Destination_Org__c testDestOrg2 = TestMethodUtilities.create(testDeployment.Id,'Draft',testToOrg.Id);
        destinationOrgs.add(testDestOrg2);

        Destination_Org__c testDestOrg3 = TestMethodUtilities.create(testDeployment.Id,'Draft',testToOrg2.Id);
        destinationOrgs.add(testDestOrg3);

        Destination_Org__c testDestOrg4 = TestMethodUtilities.create(testDeployment.Id,'Draft',testToOrg3.Id);
        destinationOrgs.add(testDestOrg4);

        Destination_Org__c testDestOrg5 = TestMethodUtilities.create(testDeployment.Id,'Draft',testToOrg4.Id);
        destinationOrgs.add(testDestOrg5);

        Destination_Org__c testDestOrg6 = TestMethodUtilities.create(testDeployment.Id,'Draft',testToOrg5.Id);
        destinationOrgs.add(testDestOrg6);

		insert destinationOrgs;
		PageReference pref = Page.DeploymentWizard;
		pref.getParameters().put('id',testDeployment.id);
		Test.setCurrentPage(pref);		

		String b = '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"'+testFromOrg.sfdc_org_id__c+'","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copa.do","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copa.do.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

		Test.startTest();
			DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(testDeployment));

			System.debug(ext.errorLevel);
			System.debug(ext.messageName);

			ext.saveDeployment();
			ext.addDestination();
        	ext.saveDestination();
            ext.getJobsManagerMatchingKey();

            // Save again with a destination Org
            ext.destinations[0] = testDestOrg2;
            ext.destinations[1] = testDestOrg3;
            ext.destinations[2] = testDestOrg4;
            ext.destinations[3] = testDestOrg5;
            ext.destinations[4] = testDestOrg6;

            ext.saveDestination();
            ext.fullCloneRedirect();
			ext.sharing();
			
			ext.addMsgOk('a');
			ext.addMsgError('a');

			ext.getDestinationsJson();
			ext.getStepsJson();
			ext.getDepJson();
			ext.getjsonMessagesQueue();

			ext.deleteDestOrg();
        
            ext.getHistoryVisible();

			DeploymentExt.sortSteps(new String[]{testStep.Id});
			DeploymentExt.deleteStep(testStep.id);	
            DeploymentExt.getisChatterEnabled();		

		Test.stopTest();
	}

    @isTest static void saveDestination() {
        setDataDML();
        List<Org__c> orgs = new List<Org__c>();
        Org__c testFromOrg = TestMethodUtilities.create('OrgName','Production','PASSWORD','SFDC_OrgId','SFDC_TOKEN','USERNAME', System.now());
        orgs.add( testFromOrg );
        Org__c testToOrg = TestMethodUtilities.create('OrgName2','Production','PASSWORD2','SFDC_OrgId2','SFDC_TOKEN2','USERNAME', System.now());
        Org__c testToOrg2 = TestMethodUtilities.create('OrgName3','Production','PASSWORD2','SFDC_OrgId3','SFDC_TOKEN3','USERNAME', System.now());
        Org__c testToOrg3 = TestMethodUtilities.create('OrgName4','Production','PASSWORD2','SFDC_OrgId4','SFDC_TOKEN4','USERNAME', System.now());
        Org__c testToOrg4 = TestMethodUtilities.create('OrgName5','Production','PASSWORD2','SFDC_OrgId5','SFDC_TOKEN5','USERNAME', System.now());
        Org__c testToOrg5 = TestMethodUtilities.create('OrgName6','Production','PASSWORD2','SFDC_OrgId6','SFDC_TOKEN6','USERNAME', System.now());
        orgs.add( testToOrg );
        orgs.add( testToOrg2 );
        orgs.add( testToOrg3 );
        orgs.add( testToOrg4 );
        orgs.add( testToOrg5 );

        insert orgs;

        Deployment__c testDeployment = TestMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Scheduled');
        insert testDeployment;
        List<Step__c> steps = new List<Step__c>();
        Step__c testStep = TestMethodUtilities.create('Step 1','attId','JSONString',testDeployment.Id,0,'Not started','MetaData');
        steps.add(testStep);
        for(Integer i = 0; i<199; i++){
            Step__c temp = TestMethodUtilities.create('Step '+i,'attId','JSONString',testDeployment.Id,0,'Not started','Manual Task');
            steps.add(temp);
        }
        insert steps;
        List<Destination_Org__c> destinationOrgs = new List<Destination_Org__c>();

        Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id,'Draft',testFromOrg.Id);
        destinationOrgs.add(testDestOrg);

        Destination_Org__c testDestOrg2 = TestMethodUtilities.create(testDeployment.Id,'Draft',testToOrg.Id);
        destinationOrgs.add(testDestOrg2);

        Destination_Org__c testDestOrg3 = TestMethodUtilities.create(testDeployment.Id,'Draft',testToOrg2.Id);
        destinationOrgs.add(testDestOrg3);

        Destination_Org__c testDestOrg4 = TestMethodUtilities.create(testDeployment.Id,'Draft',testToOrg3.Id);
        destinationOrgs.add(testDestOrg4);

        Destination_Org__c testDestOrg5 = TestMethodUtilities.create(testDeployment.Id,'Draft',testToOrg4.Id);
        destinationOrgs.add(testDestOrg5);

        Destination_Org__c testDestOrg6 = TestMethodUtilities.create(testDeployment.Id,'Draft',testToOrg5.Id);
        destinationOrgs.add(testDestOrg6);

        insert destinationOrgs;
        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id',testDeployment.id);
        Test.setCurrentPage(pref);

        Test.startTest();
        DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(testDeployment));

        ext.addDestination();
        for(Destination_Org__c dOrgs : ext.destinations){
            dOrgs.To_Org__c = testDestOrg.Id;
        }
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        ext.saveDestination();

        Test.stopTest();
    }

    @isTest static void validateOrgAndSaveDestination() {
        setDataDML();
        List<Org__c> orgs = new List<Org__c>();
        Org__c testFromOrg = TestMethodUtilities.create('OrgName','Production','PASSWORD','SFDC_OrgId','SFDC_TOKEN','USERNAME', System.now());
        orgs.add( testFromOrg );
        Org__c testToOrg = TestMethodUtilities.create('OrgName2','Production','PASSWORD2','SFDC_OrgId2','SFDC_TOKEN2','USERNAME', System.now());
        Org__c testToOrg2 = TestMethodUtilities.create('OrgName3','Production','PASSWORD2','SFDC_OrgId3','SFDC_TOKEN3','USERNAME', System.now());
        Org__c testToOrg3 = TestMethodUtilities.create('OrgName4','Production','PASSWORD2','SFDC_OrgId4','SFDC_TOKEN4','USERNAME', System.now());
        Org__c testToOrg4 = TestMethodUtilities.create('OrgName5','Production','PASSWORD2','SFDC_OrgId5','SFDC_TOKEN5','USERNAME', System.now());
        Org__c testToOrg5 = TestMethodUtilities.create('OrgName6','Production','PASSWORD2','SFDC_OrgId6','SFDC_TOKEN6','USERNAME', System.now());
        orgs.add( testToOrg );
        orgs.add( testToOrg2 );
        orgs.add( testToOrg3 );
        orgs.add( testToOrg4 );
        orgs.add( testToOrg5 );

        insert orgs;

        Deployment__c testDeployment = TestMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Scheduled');
        insert testDeployment;
        List<Step__c> steps = new List<Step__c>();
        Step__c testStep = TestMethodUtilities.create('Step 1','attId','JSONString',testDeployment.Id,0,'Not started','Git Promotion');
        steps.add(testStep);
        for(Integer i = 0; i<199; i++){
            Step__c temp = TestMethodUtilities.create('Step '+i,'attId','JSONString',testDeployment.Id,0,'Not started','Manual Task');
            steps.add(temp);
        }
        insert steps;

        List<Attachment> attachmentList = new List<Attachment>();
        Attachment att = new Attachment();
        att.Body = Blob.valueOf('{"flow_id" : "123456789" ,"target_branch" : "master"}');
        att.Name = 'Git-Promotion.json';
        att.ParentId = testStep.Id;
        attachmentList.add(att);
        insert attachmentList;

        List<Destination_Org__c> destinationOrgs = new List<Destination_Org__c>();

        Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id,'Draft',testFromOrg.Id);
        destinationOrgs.add(testDestOrg);

        Destination_Org__c testDestOrg2 = TestMethodUtilities.create(testDeployment.Id,'Draft',testToOrg.Id);
        destinationOrgs.add(testDestOrg2);

        Destination_Org__c testDestOrg3 = TestMethodUtilities.create(testDeployment.Id,'Draft',testToOrg2.Id);
        destinationOrgs.add(testDestOrg3);

        Destination_Org__c testDestOrg4 = TestMethodUtilities.create(testDeployment.Id,'Draft',testToOrg3.Id);
        destinationOrgs.add(testDestOrg4);

        Destination_Org__c testDestOrg5 = TestMethodUtilities.create(testDeployment.Id,'Draft',testToOrg4.Id);
        destinationOrgs.add(testDestOrg5);

        Destination_Org__c testDestOrg6 = TestMethodUtilities.create(testDeployment.Id,'Draft',testToOrg5.Id);
        destinationOrgs.add(testDestOrg6);

        insert destinationOrgs;
        PageReference pref = Page.DeploymentWizard;
        pref.getParameters().put('id',testDeployment.id);
        Test.setCurrentPage(pref);

        Test.startTest();
        DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(testDeployment));

        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        ext.validateFromOrg();
        ext.getJobsManagerMatchingKey();

        Test.stopTest();
    }
    
    @isTest static void testWithCCMLicense() {
        setDataDML();
        Org__c testFromOrg = TestMethodUtilities.create('OrgName','Production','PASSWORD','SFDC_OrgId','SFDC_TOKEN','USERNAME', System.now());
        insert testFromOrg;
        Deployment__c testDeployment = new Deployment__c(name='Test Deployment');
        
        PageReference pref = Page.DeploymentWizard;
        Test.setCurrentPage(pref);
        
        // Run test as a CCM User
        User userCCM = [SELECT Id FROM User WHERE Username ='user1-TestDeploymentExt@test-copado.org'];
        System.runAs(userCCM) {
            DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(testDeployment));

            System.debug(ext.errorLevel);
            System.debug(ext.messageName);
            
            Test.startTest();
            TestUtilities.exceedCopadoLicenses();
            ext.saveDeployment();
            Boolean hasErrorMessage = false;
            for(Map<String,String> m : ext.messagesQueue) {
                if(m.get('m').contains(Label.LICENSES_EXCEEDED)) {
                    hasErrorMessage = true;
                    break;
                }
            }
            System.assert(true, hasErrorMessage);    
            TestUtilities.enableLicenses(2, 2, 2);

            ext.saveDeployment();
            hasErrorMessage = false;
            for(Map<String,String> m : ext.messagesQueue) {
                if(m.get('m').contains(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED)) {
                    hasErrorMessage = true;
                    break;
                }
            }
            Test.stopTest();
            System.assert(true, hasErrorMessage);                  
        }        
    }
}