@isTest
private class TestComplianceScanResultTriggerHandler {

	@testSetup static void setupData() {
		TestUtilities.enableLicenses(2, 0, 0, 0, 2);
	}

	@isTest static void testUpdateScanResult() {
		TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, true);
        String ns = '';
        if([select id,name, namespacePrefix from apexclass where name='CopadoSetupController' and namespaceprefix='copado'].size()==1){
            ns = 'copado__';
        }
		Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
		insert gitRepo;

		Environment__c envUAT = new Environment__c(Name = 'UAT Environment', Type__c = 'Sandbox');
		insert envUAT;

		Org__c orgUAT = CMTestMethodUtilities.createOrg('UAT Org', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), envUAT.Id);
		insert orgUAT;

		Git_Backup__c gitSnapshotUAT = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgUAT.id, Branch__c = 'master');
		insert gitSnapshotUAT;

		User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory1 UAT');
		userStory1.Org_Credential__c = orgUAT.Id;
		insert userStory1;

		Deployment__c deploymentUAT = new Deployment__c(name = 'test Deploypment', From_Org__c = orgUAT.Id);
		insert deploymentUAT;

		Compliance_Scan_Result__c scanResultUserStory = new Compliance_Scan_Result__c(Status__c = 'Completed - Findings detected', Environment__c = envUAT.Id, User_Story__c = userStory1.Id, Org_Credential__c = orgUAT.Id, Git_Snapshot__c = gitSnapshotUAT.Id, Deployment__c = deploymentUAT.Id);
		insert scanResultUserStory;

		scanResultUserStory = [SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Result__c WHERE Id = :scanResultUserStory.Id];
		Test.setCreatedDate(scanResultUserStory.Id, Datetime.now().addDays(-2));

		Test.startTest();

		envUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Environment__c WHERE Id = :envUAT.Id];
		System.assertEquals('Completed - Findings detected', envUAT.Compliance_Status__c);
		System.assertEquals(scanResultUserStory.CreatedDate, envUAT.Last_Compliance_Scan_Date__c);

		orgUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Org__c WHERE Id = :orgUAT.Id];
		System.assertEquals('Completed - Findings detected', orgUAT.Compliance_Status__c);
		System.assertEquals(scanResultUserStory.CreatedDate, orgUAT.Last_Compliance_Scan_Date__c);

		userStory1 = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM User_Story__c WHERE Id = :userStory1.Id];
		System.assertEquals('Completed - Findings detected', userStory1.Compliance_Status__c);
		System.assertEquals(scanResultUserStory.CreatedDate, userStory1.Last_Compliance_Scan_Date__c);

		gitSnapshotUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Git_Backup__c WHERE Id = :gitSnapshotUAT.Id];
		System.assertEquals('Completed - Findings detected', gitSnapshotUAT.Compliance_Status__c);
		System.assertEquals(scanResultUserStory.CreatedDate, gitSnapshotUAT.Last_Compliance_Scan_Date__c);

		deploymentUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Deployment__c WHERE Id = :deploymentUAT.Id];
		System.assertEquals('Completed - Findings detected', deploymentUAT.Compliance_Status__c);
		System.assertEquals(scanResultUserStory.CreatedDate, deploymentUAT.Last_Compliance_Scan_Date__c);

		System.debug('### INSERT ScanResultDeployment');

		Compliance_Scan_Result__c scanResultDeployment = new Compliance_Scan_Result__c(Status__c = 'In Progress', Environment__c = envUAT.Id, Org_Credential__c = orgUAT.Id, Deployment__c = deploymentUAT.Id);
		insert scanResultDeployment;
		scanResultDeployment = [SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Result__c WHERE Id = :scanResultDeployment.Id];

		System.debug('### UPDATE ScanResultUserStory');

		scanResultUserStory.Status__c = 'Completed - Resolved';
		update scanResultUserStory;
		scanResultUserStory = [SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Result__c WHERE Id = :scanResultUserStory.Id];

		System.debug('### scanResultUserStory: ' + scanResultUserStory);
		System.debug('### scanResultDeployment: ' + scanResultDeployment);

		envUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Environment__c WHERE Id = :envUAT.Id];
		System.assertEquals('In Progress', envUAT.Compliance_Status__c);
		System.assertEquals(envUAT.Last_Compliance_Scan_Date__c, scanResultDeployment.CreatedDate);

		orgUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Org__c WHERE Id = :orgUAT.Id];
		System.assertEquals(orgUAT.Last_Compliance_Scan_Date__c, scanResultDeployment.CreatedDate);
		System.assertEquals('In Progress', orgUAT.Compliance_Status__c);

		userStory1 = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM User_Story__c WHERE Id = :userStory1.Id];
		System.assertEquals(userStory1.Last_Compliance_Scan_Date__c, scanResultUserStory.CreatedDate);
		System.assertEquals('Completed - Resolved', userStory1.Compliance_Status__c);

		gitSnapshotUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Git_Backup__c WHERE Id = :gitSnapshotUAT.Id];
		System.assertEquals(gitSnapshotUAT.Last_Compliance_Scan_Date__c, scanResultUserStory.CreatedDate);
		System.assertEquals('Completed - Resolved', gitSnapshotUAT.Compliance_Status__c);

		deploymentUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Deployment__c WHERE Id = :deploymentUAT.Id];
		System.assertEquals(deploymentUAT.Last_Compliance_Scan_Date__c, scanResultDeployment.CreatedDate);
		System.assertEquals('In Progress', deploymentUAT.Compliance_Status__c);

		Test.stopTest();
	}

	@isTest static void testDeleteScanResult() {
		TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, true);
		Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
		insert gitRepo;

		Environment__c envUAT = new Environment__c(Name = 'UAT Environment', Type__c = 'Sandbox');
		insert envUAT;

		Org__c orgUAT = CMTestMethodUtilities.createOrg('UAT Org', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), envUAT.Id);
		insert orgUAT;

		Git_Backup__c gitSnapshotUAT = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgUAT.id, Branch__c = 'master');
		insert gitSnapshotUAT;

		User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory1 UAT');
		userStory1.Org_Credential__c = orgUAT.Id;
		insert userStory1;

		Deployment__c deploymentUAT = new Deployment__c(name = 'test Deploypment', From_Org__c = orgUAT.Id);
		insert deploymentUAT;

		Compliance_Scan_Result__c scanResultUserStory = new Compliance_Scan_Result__c(Status__c = 'Completed - Findings detected', Environment__c = envUAT.Id, User_Story__c = userStory1.Id, Org_Credential__c = orgUAT.Id, Git_Snapshot__c = gitSnapshotUAT.Id, Deployment__c = deploymentUAT.Id);
		insert scanResultUserStory;
		scanResultUserStory = [SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Result__c WHERE Id = :scanResultUserStory.Id];
		Test.setCreatedDate(scanResultUserStory.Id, Datetime.now().addDays(-2));

		Compliance_Scan_Result__c scanResultDeployment = new Compliance_Scan_Result__c(Status__c = 'Completed - Resolved', Environment__c = envUAT.Id, Org_Credential__c = orgUAT.Id, Deployment__c = deploymentUAT.Id);
		insert scanResultDeployment;
		scanResultDeployment = [SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Result__c WHERE Id = :scanResultDeployment.Id];

		Test.startTest();

		envUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Environment__c WHERE Id = :envUAT.Id];
		System.assertEquals('Completed - Resolved', envUAT.Compliance_Status__c);

		orgUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Org__c WHERE Id = :orgUAT.Id];
		System.assertEquals('Completed - Resolved', orgUAT.Compliance_Status__c);

		userStory1 = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM User_Story__c WHERE Id = :userStory1.Id];
		System.assertEquals('Completed - Findings detected', userStory1.Compliance_Status__c);

		gitSnapshotUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Git_Backup__c WHERE Id = :gitSnapshotUAT.Id];
		System.assertEquals('Completed - Findings detected', gitSnapshotUAT.Compliance_Status__c);

		deploymentUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Deployment__c WHERE Id = :deploymentUAT.Id];
		System.assertEquals('Completed - Resolved', deploymentUAT.Compliance_Status__c);

		System.debug('### DELETE ScanResultDeployment');
		delete scanResultDeployment;

		envUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Environment__c WHERE Id = :envUAT.Id];
		System.assertEquals('Completed - Findings detected', envUAT.Compliance_Status__c);

		orgUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Org__c WHERE Id = :orgUAT.Id];
		System.assertEquals('Completed - Findings detected', orgUAT.Compliance_Status__c);

		userStory1 = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM User_Story__c WHERE Id = :userStory1.Id];
		System.assertEquals('Completed - Findings detected', userStory1.Compliance_Status__c);

		gitSnapshotUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Git_Backup__c WHERE Id = :gitSnapshotUAT.Id];
		System.assertEquals('Completed - Findings detected', gitSnapshotUAT.Compliance_Status__c);

		deploymentUAT = [SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c FROM Deployment__c WHERE Id = :deploymentUAT.Id];
		System.assertEquals('Completed - Findings detected', deploymentUAT.Compliance_Status__c);

		delete scanResultUserStory;
		undelete scanResultDeployment;

		Test.stopTest();

	}

	@isTest static void testUpdateScanResultSummaryFields() {
		TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, true);
        String ns = '';
        if([select id,name, namespacePrefix from apexclass where name='CopadoSetupController' and namespaceprefix='copado'].size()==1){
            ns = 'copado__';
        }

		Environment__c envUAT = new Environment__c(Name = 'UAT Environment', Type__c = 'Sandbox');
		insert envUAT;
		Org__c orgUAT = CMTestMethodUtilities.createOrg('UAT Org', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), envUAT.Id);
		insert orgUAT;

		Compliance_Scan_Result__c scanResultOrg = new Compliance_Scan_Result__c(Status__c = 'Completed - Findings detected', Environment__c = envUAT.Id, Org_Credential__c = orgUAT.Id);
		insert scanResultOrg;

		Map<String, String> severityPle = new Map<String, String>();
		for (Schema.PicklistEntry ple : Schema.getGlobalDescribe().get(ns+'Compliance_Rule__c').getDescribe().fields.getMap().get(ns+'Severity__c').getDescribe().getPicklistValues()) {
			severityPle.put(ple.getValue(), ple.getValue());
		}

		Map<String, String> actionPle = new Map<String, String>();
		for (Schema.PicklistEntry ple : Schema.getGlobalDescribe().get(ns+'Compliance_Rule__c').getDescribe().fields.getMap().get(ns+'Action__c').getDescribe().getPicklistValues()) {
			actionPle.put(ple.getValue(), ple.getValue());
		}
		Compliance_Rule__c rule1 = new Compliance_Rule__c(Name = 'Rule A', Severity__c = severityPle.get('Medium'), Action__c = actionPle.get('Continue with alert'));
		insert rule1;
		Compliance_Rule__c rule2 = new Compliance_Rule__c(Name = 'Rule A', Severity__c = severityPle.get('Critical'), Action__c = actionPle.get('Document Only'));
		insert rule2;

		Compliance_Finding__c findingRule1 = new Compliance_Finding__c(Compliance_Rule__c = rule1.Id, Compliance_Scan_Result__c = scanResultOrg.Id);
		insert findingRule1;

		scanResultOrg = [SELECT Id, Highest_Severity__c, Highest_Rule_Action__c FROM Compliance_Scan_Result__c WHERE Id = :scanResultOrg.Id];
		System.assertEquals('Medium', scanResultOrg.Highest_Severity__c);
		System.assertEquals('Continue with alert', scanResultOrg.Highest_Rule_Action__c);

		Compliance_Finding__c findingRule2 = new Compliance_Finding__c(Compliance_Rule__c = rule2.Id, Compliance_Scan_Result__c = scanResultOrg.Id);
		insert findingRule2;

		scanResultOrg = [SELECT Id, Highest_Severity__c, Highest_Rule_Action__c FROM Compliance_Scan_Result__c WHERE Id = :scanResultOrg.Id];
		System.assertEquals('Critical', scanResultOrg.Highest_Severity__c);
		System.assertEquals('Continue with alert', scanResultOrg.Highest_Rule_Action__c);

		delete findingRule1;
		scanResultOrg = [SELECT Id, Highest_Severity__c, Highest_Rule_Action__c FROM Compliance_Scan_Result__c WHERE Id = :scanResultOrg.Id];
		System.assertEquals('Critical', scanResultOrg.Highest_Severity__c);
		System.assertEquals('Document Only', scanResultOrg.Highest_Rule_Action__c);
	}
}