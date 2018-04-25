@isTest
private class TestComplianceFindingTriggerHandler {
	@testSetup static void setupData() {
		TestUtilities.enableLicenses(2, 0, 0, 0, 2);
	}
	@isTest static void testComplianceFindings() {
		TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, true);
        String ns = '';
        if([select id,name, namespacePrefix from apexclass where name='CopadoSetupController' and namespaceprefix='copado'].size()==1){
            ns = 'copado__';
        }
        system.debug(ns);
		Environment__c envUAT = new Environment__c(Name='UAT Environment',Type__c='Sandbox');
        insert envUAT;
        Org__c orgUAT = CMTestMethodUtilities.createOrg('UAT Org', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), envUAT.Id);
        insert orgUAT;

        Compliance_Scan_Result__c scanResultOrg = new Compliance_Scan_Result__c(Status__c = 'Completed - Findings detected', Environment__c = envUAT.Id, Org_Credential__c = orgUAT.Id);
		insert scanResultOrg;
		List<Schema.PicklistEntry> severityPle = Schema.getGlobalDescribe().get(ns+'Compliance_Rule__c').getDescribe().fields.getMap().get(ns+'Severity__c').getDescribe().getPicklistValues();
		List<Schema.PicklistEntry> actionPle = Schema.getGlobalDescribe().get(ns+'Compliance_Rule__c').getDescribe().fields.getMap().get(ns+'Action__c').getDescribe().getPicklistValues();
		Compliance_Rule__c rule1 = new Compliance_Rule__c(Name = 'Rule A', Severity__c = severityPle[0].getValue(), Action__c = actionPle[0].getValue());
		insert rule1;
		Compliance_Rule__c rule2 = new Compliance_Rule__c(Name = 'Rule A', Severity__c = severityPle[1].getValue(), Action__c = actionPle[1].getValue());
		insert rule2;

		Compliance_Finding__c findingRule1 = new Compliance_Finding__c(Compliance_Rule__c = rule1.Id, Compliance_Scan_Result__c = scanResultOrg.Id);
		insert findingRule1;
		System.assertEquals(true, findingRule1.Id != null);
		update findingRule1;
		delete findingRule1;
		undelete findingRule1;
    }
}