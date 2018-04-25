@isTest
public with sharing class TestGenerateStaticCodeAnalysisRuleSet {

	static testMethod void testGenerate() {

		Static_Code_Analysis_Settings__c scas = new Static_Code_Analysis_Settings__c(Name='Test PMD');
		Utilities.Secure_DML(scas, Utilities.DML_Action.INS, schema.Sobjecttype.Static_Code_Analysis_Settings__c); 

		testMethodUtilities.upsertOrgwideSettings();

		Test.startTest();
		GenerateStaticCodeAnalysisRuleSet gscars = new GenerateStaticCodeAnalysisRuleSet(new ApexPages.StandardController(scas));
		GenerateStaticCodeAnalysisRuleSet.generateDefaultRuleSet();
		List<Static_Code_Analysis_Rule__c> rules = [SELECT Priority__c FROM Static_Code_Analysis_Rule__c WHERE Static_Code_Analysis_Settings__c = :scas.Id];
		System.assertEquals(34, rules.size());
		System.assertEquals('3', rules[0].Priority__c);
		gscars.back();
		Test.stopTest();
	}


}