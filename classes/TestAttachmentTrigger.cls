@isTest
private class TestAttachmentTrigger {
    @testSetup
    static void setupData() {
        Utilities.Secure_DML(TestUtilities.getTestSettings(), Utilities.DML_Action.INS, schema.Sobjecttype.Settings__c);
        //TestUtilities.enableLicenses(10, 10, 10);
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false);
        CMTestMethodUtilities.enableSelenium();
    }
	static testMethod void testNotifications() {
		List<String> supportedNames = new List<String>();
		supportedNames.add('DEPLOYMENT_STATUS_COPADO');
        supportedNames.add('PROGRESS_STATUS_COPADO');
        supportedNames.add('TEST_PROGRESS_STATUS_COPADO');

        String b1 = '{"status":"In Progress","type":"Type 1"}';
        String b2 = '{"status":"In Progress","type":"Type 2", "parent2id":"test123"}';
        String b3 = '{"status":"In Progress","type":"Type 3", "SomeValue":"12345678901234567890123456789012345678901234567890", "parent2id":"12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"}';

        User_Story__c us = new User_Story__c();
        Utilities.Secure_DML(us, Utilities.DML_Action.INS, schema.Sobjecttype.User_Story__c);    

        List<Attachment> atts = new List<Attachment>();
        atts.add(createAttachment(us.Id, supportedNames[1], b1));
        atts.add(createAttachment(us.Id, supportedNames[2], b2));
        atts.add(createAttachment(us.Id, supportedNames[0], b3));
        Utilities.Secure_DML(atts, Utilities.DML_Action.INS, schema.Sobjecttype.Attachment); 

        List<Copado_Notification__c> results = [SELECT Id, Name, ParentId__c, AttachmentId__c, Type__c, Parent2Id__c, Message__c
        	FROM Copado_Notification__c limit 3];
    	system.assertEquals(3, results.size());
    	for(Copado_Notification__c cn : results){
    		if(cn.Name==supportedNames[1]){
    			system.assert(!String.isBlank(cn.ParentId__c));
    			system.assertEquals(null, cn.Parent2Id__c);
    			system.assert(!String.isBlank(cn.AttachmentId__c));
    			system.assertEquals('Type 1', cn.Type__c);
    			system.assert(!String.isBlank(cn.Message__c));
    		}
    		if(cn.Name==supportedNames[2]){
    			system.assert(!String.isBlank(cn.ParentId__c));
    			system.assert(!String.isBlank(cn.Parent2Id__c));
    			system.assert(!String.isBlank(cn.AttachmentId__c));
    			system.assertEquals('Type 2', cn.Type__c);
    			system.assert(!String.isBlank(cn.Message__c));
    		}
    		if(cn.Name==supportedNames[0]){
    			system.assert(!String.isBlank(cn.ParentId__c));
    			system.assert(!String.isBlank(cn.Parent2Id__c));
    			system.assert(!String.isBlank(cn.AttachmentId__c));
    			system.assertEquals('Type 3', cn.Type__c);
    			system.assert(String.isBlank(cn.Message__c));
    		}
    	}
	}
	private static Attachment createAttachment(String parentId, String name, String body){
		Attachment a = new Attachment(parentId=parentId, name=name);
		a.Body = Blob.valueOf(body);
		return a;
	}
    /*@testSetup static void setupTestData(){
        CMTestMethodUtilities.enableSelenium();
    }*/
    static testMethod void testLocators() {
        String b1 = '{ "commands": [ {"command": "copadoSalesforceLogin", "target": "copadoSalesforceLogin", "context": {"pageref": ""}, "value": null }, {"command": "copadoSelectApp", "target": "Force.com", "context": {"pageref": ""}, "value": null }, {"command": "selectWindow", "target": null, "context": {"pageref": ""}, "value": null }, {"command": "copadoSelectTab", "target": "{!Locator.HOME}", "context": {"pageref": ""}, "value": null }, {"command": "open", "target": "/home/home.jsp", "context": {"pageref": ""}, "value": null }, {"command": "clickAndWait", "target": "//img[@alt=\'All Tabs\']", "context": {"pageref": ""}, "value": null }, {"command": "copadoSelectTabAndWait", "target": "Opportunities", "context": {"pageref": ""}, "value": null }, {"command": "clickAndWait", "target": "name=new", "context": {"pageref": ""}, "value": null }, {"command": "type", "target": "copado=@*Opportunity Name", "context": {"pageref": ""}, "value": "UT2!test" }, {"command": "click", "target": "css=span.dateFormat > a", "context": {"pageref": ""}, "value": null }, {"command": "type", "target": "copado=@*Close Date", "context": {"pageref": ""}, "value": "29/06/2016" }, {"command": "select", "target": "copado=@*Stage", "context": {"pageref": ""}, "value": "label=Prospecting" }, {"command": "clickAndWait", "target": "xpath=(//input[@name=\'save\'])", "context": {"pageref": ""}, "value": null }, {"command": "clickAndWait", "target": "name=addProd", "context": {"pageref": ""}, "value": null }, {"command": "type", "target": "name=search", "context": {"pageref": ""}, "value": "gasoline" }, {"command": "click", "target": "name=saveButton", "context": {"pageref": ""}, "value": null }, {"command": "click", "target": "copado=productCheck:GenWatt Gasoline 2000kW", "context": {"pageref": ""}, "value": null }, {"command": "click", "target": "copado=productCheck:GenWatt Gasoline 300kW", "context": {"pageref": ""}, "value": null }, {"command": "clickAndWait", "target": "name=edit", "context": {"pageref": ""}, "value": null }, {"command": "type", "target": "copado=@*Quantity", "context": {"pageref": ""}, "value": "1" }, {"command": "type", "target": "copado=@*Sales Price", "context": {"pageref": ""}, "value": "32332" }, {"command": "click", "target": "name=Quantity01u24000001qlp0", "context": {"pageref": ""}, "value": null }, {"command": "type", "target": "name=Quantity01u24000001qlp0", "context": {"pageref": ""}, "value": "2" }, {"command": "clickAndWait", "target": "xpath=(//input[@name=\'save\'])[2]", "context": {"pageref": ""}, "value": null } ], "name": "create-opportunity-and-products1", "baseurl": "https://dev-copado-dev-ed.my.salesforce.com/" }';
        String b2 = '{ "commands": [ {"command": "copadoSalesforceLogin2", "target": "copadoSalesforceLogin2", "context": {"pageref": "Salesforce Customer Login"}, "value": null }, {"command": "copadoSelectApp", "target": "Force.com", "context": {"pageref": ""}, "value": null }, {"command": "selectWindow", "target": null, "context": {"pageref": ""}, "value": null }, {"command": "copadoSelectTab", "target": "{!Locator.HOME}","context": {"pageref": ""}, "value": null }, {"command": "open", "target": "/home/home.jsp", "context": {"pageref": ""}, "value": null }, {"command": "clickAndWait", "target": "//img[@alt=\'All Tabs\']", "context": {"pageref": ""}, "value": null }, {"command": "copadoSelectTabAndWait", "target": "Opportunities", "context": {"pageref": ""}, "value": null }, {"command": "clickAndWait", "target": "name=new", "context": {"pageref": ""}, "value": null }, {"command": "type", "target": "copado=@*Opportunity Name", "context": {"pageref": ""}, "value": "UT2!test" }, {"command": "click", "target": "css=span.dateFormat > a", "context": {"pageref": ""}, "value": null }, {"command": "type", "target": "copado=@*Close Date", "context": {"pageref": ""}, "value": "29/06/2016" }, {"command": "select", "target": "copado=@*Stage", "context": {"pageref": ""}, "value": "label=Prospecting" }, {"command": "clickAndWait", "target": "xpath=(//input[@name=\'save\'])", "context": {"pageref": ""}, "value": null }, {"command": "clickAndWait", "target": "name=addProd", "context": {"pageref": ""}, "value": null }, {"command": "type", "target": "name=search", "context": {"pageref": ""}, "value": "gasoline" }, {"command": "click", "target": "name=saveButton", "context": {"pageref": ""}, "value": null }, {"command": "click", "target": "copado=productCheck:GenWatt Gasoline 2000kW", "context": {"pageref": ""}, "value": null }, {"command": "click", "target": "copado=productCheck:GenWatt Gasoline 300kW", "context": {"pageref": ""}, "value": null }, {"command": "clickAndWait", "target": "name=edit", "context": {"pageref": ""}, "value": null }, {"command": "type", "target": "copado=@*Quantity", "context": {"pageref": ""}, "value": "1" }, {"command": "type", "target": "copado=@*Sales Price", "context": {"pageref": ""}, "value": "32332" }, {"command": "click", "target": "name=Quantity01u24000001qlp0", "context": {"pageref": ""}, "value": null }, {"command": "type", "target": "name=Quantity01u24000001qlp0", "context": {"pageref": ""}, "value": "2" }, {"command": "clickAndWait", "target": "xpath=(//input[@name=\'save\'])[2]", "context": {"pageref": ""}, "value": null } ], "name": "create-opportunity-and-products1", "baseurl": "https://dev-copado-dev-ed.my.salesforce.com/" }';

        Selenium_Locator__c l = new Selenium_Locator__c(Locator_ID__c='HOME', Locator__c='link=home');        
        Utilities.Secure_DML(l, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Locator__c); 
    
        Selenium_Test_Case__c tc = new Selenium_Test_Case__c(Name = 'Test case x');        
        Utilities.Secure_DML(tc, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Test_Case__c); 

        Selenium_Test_Case__c tc1 = new Selenium_Test_Case__c(Name = 'Test case x2');
        Utilities.Secure_DML(tc1, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Test_Case__c); 
        
        List<Attachment> atts = new List<Attachment>();
        atts.add(createAttachment(tc.Id, 'Copado.SeleniumTestCase.json', b1));
        atts.add(createAttachment(tc1.Id, 'Copado.SeleniumTestCase.json', b2));        
        Utilities.Secure_DML(atts, Utilities.DML_Action.INS, schema.Sobjecttype.Attachment); 
        
        List<Selenium_Locator__c> locators = [select Locator__c, Page__c, External_ID__c from Selenium_Locator__c];
        system.assert(locators.size() > 0);
        
        List<Selenium_Locator_Reference__c> refs = [select Selenium_Locator__c, Selenium_Test_Case__c , External_ID__c from Selenium_Locator_Reference__c];
        system.assert(refs.size() > 0);

        system.assertEquals(1,[select count() from Selenium_Locator__c where External_ID__c  = :AttachmentTriggerHelper.getLocatorExternalID('','copadoSalesforceLogin')]);
        system.assertEquals(1,[select count() from Selenium_Locator__c where External_ID__c  = :AttachmentTriggerHelper.getLocatorExternalID('','Force.com')]);
		
        Id locatorId = [SELECT Id from Selenium_Locator__c where External_ID__c  = :AttachmentTriggerHelper.getLocatorExternalID('','Force.com')].Id;
        system.assertEquals(2,[select count() from Selenium_Locator_Reference__c where Selenium_Locator__c = : locatorId ]);

        system.assertEquals(1,[select count() from Selenium_Locator_Reference__c where External_ID__c  = :AttachmentTriggerHelper.getLocatorExternalID('','copadoSalesforceLogin')+tc.Id]);
        system.assertEquals(0,[select count() from Selenium_Locator_Reference__c where External_ID__c  = :AttachmentTriggerHelper.getLocatorExternalID('Salesforce Customer Login','copadoSalesforceLogin2')+tc.Id]);

        system.assertEquals(1,[select count() from Selenium_Locator__c where Locator_ID__c='HOME']);
        system.assertEquals(2,[select count() from Selenium_Locator_Reference__c where Selenium_Locator__c = : l.Id]);
        
        //test deletion of references. locators stays, references get deleted        
        Utilities.Secure_DML(atts, Utilities.DML_Action.DEL, schema.Sobjecttype.Attachment); 
        system.assertEquals(1,[select count() from Selenium_Locator__c where External_ID__c  = :AttachmentTriggerHelper.getLocatorExternalID('','copadoSalesforceLogin')]);
        refs = [select Selenium_Locator__c, Selenium_Test_Case__c, External_ID__c from Selenium_Locator_Reference__c];
        system.assertEquals(0,refs.size());
	}

    static testMethod void testDeploymentFlowAttachments() {
        List<String> supportedMetadataNames = new List<String>();
        supportedMetadataNames.add('result.json'); 

        User_Story__c us = new User_Story__c();
        insert us;

        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;

        Environment__c envDev1 = CMTestMethodUtilities.createEnvironment('Dev1 Environment', 'SFDC_OrgId');
        insert envDev1;
        Environment__c envInt = CMTestMethodUtilities.createEnvironment('Int Environment', 'SFDC_OrgId2');
        insert envInt;
        Environment__c envProd = CMTestMethodUtilities.createEnvironment('Prod Environment', 'SFDC_OrgId3');
        insert envProd;

        Org__c testOrgDev1 = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), envDev1.Id);
        insert testOrgDev1;
        Org__c testOrgInt = CMTestMethodUtilities.createOrg('MyOrgInt', 'Sandbox', null, 'SFDC_OrgId2', null, null, system.now(), envInt.Id);
        insert testOrgInt;
        Org__c testOrgProd = CMTestMethodUtilities.createOrg('MyOrgProd', 'Production', null, 'SFDC_OrgId3', null, null, system.now(), envProd.Id);
        insert testOrgProd;

        Deployment_Flow_Step__c flowStepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flow.Id);
        insert flowStepDev1ToInt;
        Deployment_Flow_Step__c flowStepIntToProd = CMTestMethodUtilities.createFlowStep(envInt.Id, envProd.Id, flow.Id);
        insert flowStepIntToProd;

		System.debug('### START flow attachment process');
        String bodyFlow = '[{"mergeCompareCommits":"0a8a1ead9dc9d94383fedc20b55489b945f31ebe_vs_23ec58e58add1f0f089f7bb3bc3421139f2b9091","pullMergeResult":"CONFLICTING","sourceBranch":"dev1","pullCompareCommits":"23ec58e58add1f0f089f7bb3bc3421139f2b9091_vs_0a8a1ead9dc9d94383fedc20b55489b945f31ebe","mergeMergeResult":"CONFLICTING","pullCompareBranches":"int_vs_dev1","filesMergedBehind":[{"d":"update","f":"labels/CustomLabels.labels"}],"mergeDone":true,"mergeTimestamp":"1503588813000","commitsBehind":1,"filesMergedConflictBehind":["labels/CustomLabels.labels","classes/AccountOperations.cls"],"commitsAhead":2,"pullDestinationCommit":"0a8a1ead9dc9d94383fedc20b55489b945f31ebe","mergeDestinationCommit":"23ec58e58add1f0f089f7bb3bc3421139f2b9091","mergeSuccess":true,"pullSuccess":true,"mergeCompareBranches":"dev1_vs_int","mergeSourceCommit":"0a8a1ead9dc9d94383fedc20b55489b945f31ebe","filesMergedConflictAhead":["labels/CustomLabels.labels"],"id":"'+flowStepDev1ToInt.Id+'","pullSourceCommit":"23ec58e58add1f0f089f7bb3bc3421139f2b9091","pullDone":true,"destinationBranch":"int","filesMergedAhead":[{"d":"create","f":"classes/AccountOperationsTest.cls-meta.xml"},{"d":"create","f":"classes/AccountOperationsTest.cls"},{"d":"update","f":"labels/CustomLabels.labels"},{"d":"update","f":"classes/AccountOperations.cls"},{"d":"update","f":"layouts/CaseClose-Close Case Layout.layout"}]},';
        bodyFlow = bodyFlow + '{"mergeCompareCommits":"082c387869eb4d34ac7ff2bc533042b8c89a024e_vs_23ec58e58add1f0f089f7bb3bc3421139f2b9091","pullMergeResult":"MERGED","sourceBranch":"int","pullCompareCommits":"23ec58e58add1f0f089f7bb3bc3421139f2b9091_vs_082c387869eb4d34ac7ff2bc533042b8c89a024e","mergeMergeResult":"MERGED","pullCompareBranches":"master_vs_int","filesMergedBehind":[{"d":"update","f":"labels/CustomLabels.labels"}],"mergeDone":true,"mergeTimestamp":"1503588813000","commitsBehind":1,"filesMergedConflictBehind":["classes/AccountOperations.cls"],"commitsAhead":3,"pullDestinationCommit":"082c387869eb4d34ac7ff2bc533042b8c89a024e","mergeDestinationCommit":"23ec58e58add1f0f089f7bb3bc3421139f2b9091","mergeSuccess":true,"pullSuccess":true,"mergeCompareBranches":"int_vs_master","mergeSourceCommit":"082c387869eb4d34ac7ff2bc533042b8c89a024e","filesMergedConflictAhead":[],"id":"'+flowStepIntToProd.Id+'","ullSourceCommit":"23ec58e58add1f0f089f7bb3bc3421139f2b9091","pullDone":true,"destinationBranch":"master","filesMergedAhead":[{"d":"update","f":"labels/CustomLabels.labels"}]}]';
        Attachment attachmentFlow = createAttachment(flow.Id, supportedMetadataNames[0], bodyFlow);
        insert attachmentFlow;

        Test.startTest();

        // Case 1.
        flowStepDev1ToInt = [SELECT Id, Sync_Merge_State__c, Sync_Pull_State__c, Commits_Ahead__c, Commits_Behind__c, Destination_Branch__c, Merge_Auto_Resolved_Files__c, Pull_Auto_Resolved_Files__c, Last_Merge_CBM_Sync__c, Last_Pull_CBM_Sync__c FROM Deployment_Flow_Step__c WHERE Id = :flowStepDev1ToInt.Id];
        flowStepIntToProd = [SELECT Id, Sync_Merge_State__c, Sync_Pull_State__c, Commits_Ahead__c, Commits_Behind__c, Destination_Branch__c, Merge_Auto_Resolved_Files__c, Pull_Auto_Resolved_Files__c, Last_Merge_CBM_Sync__c, Last_Pull_CBM_Sync__c FROM Deployment_Flow_Step__c WHERE Id = :flowStepIntToProd.Id];
        System.assertEquals('int', flowStepDev1ToInt.Destination_Branch__c);
        System.assertEquals('master', flowStepIntToProd.Destination_Branch__c);
        System.assertEquals(2, flowStepDev1ToInt.Commits_Ahead__c);
        System.assertEquals(1, flowStepDev1ToInt.Commits_Behind__c);
        System.assertEquals(3, flowStepIntToProd.Commits_Ahead__c);
        System.assertEquals(1, flowStepIntToProd.Commits_Behind__c);
        System.assertEquals(1, ((flowStepDev1ToInt.Merge_Auto_Resolved_Files__c).split(',')).size());
        System.assertEquals(2, ((flowStepDev1ToInt.Pull_Auto_Resolved_Files__c).split(',')).size());
        System.assertEquals(null, flowStepIntToProd.Merge_Auto_Resolved_Files__c);
        System.assertEquals('classes/AccountOperations.cls', flowStepIntToProd.Pull_Auto_Resolved_Files__c);
        System.assertEquals(null, flowStepDev1ToInt.Last_Merge_CBM_Sync__c);
        System.assertEquals(null, flowStepDev1ToInt.Last_Pull_CBM_Sync__c);
        System.assertEquals(null, flowStepIntToProd.Last_Merge_CBM_Sync__c);
        System.assertEquals(null, flowStepIntToProd.Last_Pull_CBM_Sync__c);
        
        // Case 2.
        // Commits Ahead and Behind are now 0 in flowStepIntToProd due to Promoting and Syncing activity of the user.
        String bodyFlow2 = '[{"mergeCompareCommits":"0a8a1ead9dc9d94383fedc20b55489b945f31ebe_vs_23ec58e58add1f0f089f7bb3bc3421139f2b9091","pullMergeResult":"CONFLICTING","sourceBranch":"dev1","pullCompareCommits":"23ec58e58add1f0f089f7bb3bc3421139f2b9091_vs_0a8a1ead9dc9d94383fedc20b55489b945f31ebe","mergeMergeResult":"CONFLICTING","pullCompareBranches":"int_vs_dev1","filesMergedBehind":[{"d":"update","f":"labels/CustomLabels.labels"}],"mergeDone":true,"mergeTimestamp":"1503588813000","commitsBehind":1,"filesMergedConflictBehind":["labels/CustomLabels.labels"],"commitsAhead":0,"pullDestinationCommit":"0a8a1ead9dc9d94383fedc20b55489b945f31ebe","mergeDestinationCommit":"23ec58e58add1f0f089f7bb3bc3421139f2b9091","mergeSuccess":true,"pullSuccess":true,"mergeCompareBranches":"dev1_vs_int","mergeSourceCommit":"0a8a1ead9dc9d94383fedc20b55489b945f31ebe","filesMergedConflictAhead":["labels/CustomLabels.labels"],"id":"'+flowStepDev1ToInt.Id+'","pullSourceCommit":"23ec58e58add1f0f089f7bb3bc3421139f2b9091","pullDone":true,"destinationBranch":"int","filesMergedAhead":[{"d":"create","f":"classes/AccountOperationsTest.cls-meta.xml"},{"d":"create","f":"classes/AccountOperationsTest.cls"},{"d":"update","f":"labels/CustomLabels.labels"},{"d":"update","f":"classes/AccountOperations.cls"},{"d":"update","f":"layouts/CaseClose-Close Case Layout.layout"}]},';
        bodyFlow2 = bodyFlow2 + '{"mergeCompareCommits":"082c387869eb4d34ac7ff2bc533042b8c89a024e_vs_23ec58e58add1f0f089f7bb3bc3421139f2b9091","pullMergeResult":"MERGED","sourceBranch":"int","pullCompareCommits":"23ec58e58add1f0f089f7bb3bc3421139f2b9091_vs_082c387869eb4d34ac7ff2bc533042b8c89a024e","mergeMergeResult":"MERGED","pullCompareBranches":"master_vs_int","filesMergedBehind":[{"d":"update","f":"labels/CustomLabels.labels"}],"mergeDone":true,"mergeTimestamp":"1503588813000","commitsBehind":0,"filesMergedConflictBehind":[],"commitsAhead":0,"pullDestinationCommit":"082c387869eb4d34ac7ff2bc533042b8c89a024e","mergeDestinationCommit":"23ec58e58add1f0f089f7bb3bc3421139f2b9091","mergeSuccess":true,"pullSuccess":true,"mergeCompareBranches":"int_vs_master","mergeSourceCommit":"082c387869eb4d34ac7ff2bc533042b8c89a024e","filesMergedConflictAhead":[],"id":"'+flowStepIntToProd.Id+'","ullSourceCommit":"23ec58e58add1f0f089f7bb3bc3421139f2b9091","pullDone":true,"destinationBranch":"master","filesMergedAhead":[{"d":"update","f":"labels/CustomLabels.labels"}]}]';
     
        // The fields Merge_Validation_Success and Pull_Validation_Success are true and thanks to the flow step attachment trigger. Now, they will become false since the commitsAhead and Behind have become 0.   
        flowStepDev1ToInt.Sync_Merge_State__c = AttachmentTriggerHelper.DFS_INSYNC;
        flowStepDev1ToInt.Sync_Pull_State__c = AttachmentTriggerHelper.DFS_INSYNC;
        flowStepIntToProd.Sync_Merge_State__c = AttachmentTriggerHelper.DFS_INSYNC;
        flowStepIntToProd.Sync_Pull_State__c = AttachmentTriggerHelper.DFS_INSYNC;
        flowStepDev1ToInt.Commits_Ahead__c = 1;
        update flowStepDev1ToInt;
        update flowStepIntToProd;

        // Update the attachment
        attachmentFlow.Body = Blob.valueOf(bodyFlow2);
        update attachmentFlow;

        // set the STEP attachment, with everything validated
        String bodyDev1ToInt = '{"mergeValidationDone":true,"pullValidationSuccess":true,"pullValidationDone":true,"mergeValidationStatus":"Completed","pullValidationErrors":[],"id":"a090Y000004fNMiQAM","pullValidationStatus":"Completed","mergeValidationSuccess":true,"mergeValidationErrors":[]}';
        Attachment attachmentStep = createAttachment(flowStepDev1ToInt.Id, supportedMetadataNames[0], bodyDev1ToInt);
        insert attachmentStep;

        flowStepDev1ToInt = [SELECT Id, Sync_Merge_State__c, Sync_Pull_State__c, Commits_Ahead__c, Commits_Behind__c, Destination_Branch__c, Merge_Auto_Resolved_Files__c, Pull_Auto_Resolved_Files__c, Last_Merge_CBM_Sync__c, Last_Pull_CBM_Sync__c FROM Deployment_Flow_Step__c WHERE Id = :flowStepDev1ToInt.Id];
        flowStepIntToProd = [SELECT Id, Sync_Merge_State__c, Sync_Pull_State__c, Commits_Ahead__c, Commits_Behind__c, Destination_Branch__c, Merge_Auto_Resolved_Files__c, Pull_Auto_Resolved_Files__c, Last_Merge_CBM_Sync__c, Last_Pull_CBM_Sync__c FROM Deployment_Flow_Step__c WHERE Id = :flowStepIntToProd.Id];
        System.assertEquals(0, flowStepDev1ToInt.Commits_Ahead__c);
        System.assertEquals(1, flowStepDev1ToInt.Commits_Behind__c);
        System.debug('flowStepDev1ToInt '+flowStepDev1ToInt);
        System.assertEquals(AttachmentTriggerHelper.DFS_INSYNC, flowStepDev1ToInt.Sync_Merge_State__c);
        System.assertEquals('Validated', flowStepDev1ToInt.Sync_Pull_State__c);
        System.assertEquals(0, flowStepIntToProd.Commits_Ahead__c);
        System.assertEquals(0, flowStepIntToProd.Commits_Behind__c);

        System.assertEquals(AttachmentTriggerHelper.DFS_INSYNC, flowStepIntToProd.Sync_Merge_State__c);
        System.assertEquals(AttachmentTriggerHelper.DFS_INSYNC, flowStepIntToProd.Sync_Pull_State__c);
        System.assertEquals(true, flowStepDev1ToInt.Last_Merge_CBM_Sync__c != null);
        System.assertEquals(null, flowStepDev1ToInt.Last_Pull_CBM_Sync__c);
        System.assertEquals(true, flowStepIntToProd.Last_Merge_CBM_Sync__c != null);
        System.assertEquals(true, flowStepIntToProd.Last_Pull_CBM_Sync__c != null);

        // Case 3. With an empty attachment, all fields should reset to  null/false/0 values and In_Sync__c should be true.
        String bodyFlow3 = '[{"id":"'+flowStepDev1ToInt.Id+'"},{"id":"'+flowStepIntToProd.Id+'"}]';
        attachmentFlow.Body = Blob.valueOf(bodyFlow3);
        upsert attachmentFlow;

        flowStepDev1ToInt = [SELECT Id, Sync_Merge_State__c, Sync_Pull_State__c, Commits_Ahead__c, Commits_Behind__c, Destination_Branch__c, Merge_Auto_Resolved_Files__c, Pull_Auto_Resolved_Files__c, Last_Merge_CBM_Sync__c, Last_Pull_CBM_Sync__c FROM Deployment_Flow_Step__c WHERE Id = :flowStepDev1ToInt.Id];
        flowStepIntToProd = [SELECT Id, Sync_Merge_State__c, Sync_Pull_State__c, Commits_Ahead__c, Commits_Behind__c, Destination_Branch__c, Merge_Auto_Resolved_Files__c, Pull_Auto_Resolved_Files__c, Last_Merge_CBM_Sync__c, Last_Pull_CBM_Sync__c FROM Deployment_Flow_Step__c WHERE Id = :flowStepIntToProd.Id];
        
        System.debug('### flowStepDev1ToInt: '+flowStepDev1ToInt);
        System.debug('### flowStepIntToProd: '+flowStepIntToProd);
        System.assertEquals(0, flowStepDev1ToInt.Commits_Ahead__c);
        System.assertEquals(0, flowStepDev1ToInt.Commits_Behind__c);
        System.assertEquals(AttachmentTriggerHelper.DFS_INSYNC, flowStepDev1ToInt.Sync_Merge_State__c);
        System.assertEquals(AttachmentTriggerHelper.DFS_INSYNC, flowStepDev1ToInt.Sync_Pull_State__c);
        System.assertEquals(0, flowStepIntToProd.Commits_Ahead__c);
        System.assertEquals(0, flowStepIntToProd.Commits_Behind__c);
        System.assertEquals(AttachmentTriggerHelper.DFS_INSYNC, flowStepIntToProd.Sync_Merge_State__c);
        System.assertEquals(AttachmentTriggerHelper.DFS_INSYNC, flowStepIntToProd.Sync_Pull_State__c);
		System.assertEquals(null, flowStepDev1ToInt.Merge_Auto_Resolved_Files__c);
        System.assertEquals(null, flowStepDev1ToInt.Pull_Auto_Resolved_Files__c);
        System.assertEquals(null, flowStepIntToProd.Merge_Auto_Resolved_Files__c);
        System.assertEquals(null, flowStepIntToProd.Pull_Auto_Resolved_Files__c);
        System.assertEquals(true, flowStepDev1ToInt.Last_Merge_CBM_Sync__c != null);
        System.assertEquals(true, flowStepDev1ToInt.Last_Pull_CBM_Sync__c != null);
        System.assertEquals(true, flowStepIntToProd.Last_Merge_CBM_Sync__c != null);
        System.assertEquals(true, flowStepIntToProd.Last_Pull_CBM_Sync__c != null);

        Test.stopTest();
    }
    static testMethod void testDeploymentFlowStepAttachments() {
        List<String> supportedMetadataNames = new List<String>();
        supportedMetadataNames.add('result.json'); 

        String bodyFlow = '{"mergeValidationDone":true,"pullValidationSuccess":true,"pullValidationDone":true,"mergeValidationStatus":"Completed","pullValidationErrors":[],"id":"a090Y000004fNMiQAM","pullValidationStatus":"Completed","mergeValidationSuccess":true,"mergeValidationErrors":[]}';
        String bodyDev1ToInt = '{"mergeValidationDone":true,"pullValidationSuccess":true,"pullValidationDone":true,"mergeValidationStatus":"Completed","pullValidationErrors":[],"id":"a090Y000004fNMiQAM","pullValidationStatus":"Completed","mergeValidationSuccess":true,"mergeValidationErrors":[]}';
        String bodyIntToProd = '{"mergeValidationDone":true,"mergeValidationStatus":"Completed","id":"a090Y000004fNMiQAM","mergeValidationSuccess":true,"mergeValidationErrors":[]}';
        String bodyIntToProd2 = '{"mergeValidationDone":true,"mergeValidationStatus":"Completed","id":"a090Y000004fNMiQAM","mergeValidationSuccess":false,"mergeValidationErrors":[]}';

        User_Story__c us = new User_Story__c();
        insert us;

        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;

        Environment__c envDev1 = CMTestMethodUtilities.createEnvironment('Dev1 Environment', 'SFDC_OrgId');
        insert envDev1;
        Environment__c envInt = CMTestMethodUtilities.createEnvironment('Int Environment', 'SFDC_OrgId2');
        insert envInt;
        Environment__c envProd = CMTestMethodUtilities.createEnvironment('Prod Environment', 'SFDC_OrgId3');
        insert envProd;

        Org__c testOrgDev1 = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), envDev1.Id);
        insert testOrgDev1;
        Org__c testOrgInt = CMTestMethodUtilities.createOrg('MyOrgInt', 'Sandbox', null, 'SFDC_OrgId2', null, null, system.now(), envInt.Id);
        insert testOrgInt;
        Org__c testOrgProd = CMTestMethodUtilities.createOrg('MyOrgProd', 'Production', null, 'SFDC_OrgId3', null, null, system.now(), envProd.Id);
        insert testOrgProd;

        Deployment_Flow_Step__c flowStepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flow.Id);
        insert flowStepDev1ToInt;
        Deployment_Flow_Step__c flowStepIntToProd = CMTestMethodUtilities.createFlowStep(envInt.Id, envProd.Id, flow.Id);
        flowStepIntToProd.Commits_Ahead__c = 0;
        flowStepIntToProd.Commits_Behind__c = 2;
        insert flowStepIntToProd;

        Attachment attachmentStepDev1ToInt = createAttachment(flowStepDev1ToInt.Id, supportedMetadataNames[0], bodyDev1ToInt);
        insert attachmentStepDev1ToInt;
        Attachment attachmentStepIntToProd = createAttachment(flowStepIntToProd.Id, supportedMetadataNames[0], bodyIntToProd);
        insert attachmentStepIntToProd;

        Test.startTest();

        flowStepDev1ToInt = [SELECT Id, Sync_Merge_State__c, Sync_Pull_State__c FROM Deployment_Flow_Step__c WHERE Id = :flowStepDev1ToInt.Id];
        System.assertEquals(AttachmentTriggerHelper.DFS_INSYNC, flowStepDev1ToInt.Sync_Merge_State__c);
        System.assertEquals(AttachmentTriggerHelper.DFS_INSYNC, flowStepDev1ToInt.Sync_Pull_State__c);

        // There are commits behind in flowStepIntToProd, so the status is NOT in sync for pull, but it is for merge.
        flowStepIntToProd = [SELECT Id, Sync_Merge_State__c, Sync_Pull_State__c FROM Deployment_Flow_Step__c WHERE Id = :flowStepIntToProd.Id];
        System.assertEquals(AttachmentTriggerHelper.DFS_INSYNC, flowStepIntToProd.Sync_Merge_State__c);
        System.assertNotEquals(AttachmentTriggerHelper.DFS_INSYNC, flowStepIntToProd.Sync_Pull_State__c);

        attachmentStepIntToProd.Body = Blob.valueOf(bodyIntToProd2);
        update attachmentStepIntToProd;
        flowStepIntToProd = [SELECT Id, Sync_Merge_State__c, Sync_Pull_State__c FROM Deployment_Flow_Step__c WHERE Id = :flowStepIntToProd.Id];
        System.assertEquals(AttachmentTriggerHelper.DFS_INSYNC, flowStepIntToProd.Sync_Merge_State__c);
        System.assertNotEquals(AttachmentTriggerHelper.DFS_INSYNC, flowStepIntToProd.Sync_Pull_State__c);
        
        Test.stopTest();
    }
}