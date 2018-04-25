public with sharing class GenerateStaticCodeAnalysisRuleSet {
	
	public static Id scaSettingsId {get;set;}
	public static List<Static_Code_Analysis_Rule__c> apexRules {get;set;}
	public static Map<String,String> apexRuleMessages {get;set;}
	
	public GenerateStaticCodeAnalysisRuleSet(ApexPages.StandardController std) {
        scaSettingsId = std.getId();
        apexRuleMessages = new Map<String,String>();
        apexRuleMessages.put('ExcessiveClassLength', 'Avoid really long classes (lines of code)');
		apexRuleMessages.put('ExcessiveParameterList', 'Avoid long parameter lists');
		apexRuleMessages.put('ExcessivePublicCount', 'This class has too many public methods and attributes');
		apexRuleMessages.put('NcssConstructorCount', 'The constructor has a high NCSS line count');
		apexRuleMessages.put('NcssMethodCount', 'This method has a high NCSS line count');
		apexRuleMessages.put('NcssTypeCount', 'The type has a high NCSS');
		apexRuleMessages.put('StdCyclomaticComplexity', 'Class or method has a high Standard Cyclomatic Complexity.');
		apexRuleMessages.put('TooManyFields', 'Too many fields');
		apexRuleMessages.put('AvoidDeeplyNestedIfStmts', 'Deeply nested if..else statements are hard to read');
		apexRuleMessages.put('AvoidSoqlInLoops', 'Avoid Soql queries inside loops');
		apexRuleMessages.put('AvoidDmlStatementsInLoops', 'Avoid DML Statements inside loops');
		apexRuleMessages.put('AvoidLogicInTrigger', 'Avoid logic in triggers');
		apexRuleMessages.put('AvoidGlobalModifier', 'Avoid using global modifier');
		apexRuleMessages.put('ClassNamingConventions', 'Class names should begin with an uppercase character');
		apexRuleMessages.put('MethodNamingConventions', 'Method name does not begin with a lower case character.');
		apexRuleMessages.put('MethodWithSameNameAsEnclosingClass', 'Classes should not have non-constructor methods with the same name as the class');
		apexRuleMessages.put('VariableNamingConventions', 'Variable naming convention violation.');
		apexRuleMessages.put('ApexUnitTestShouldNotUseSeeAllDataTrue', '@isTest(seeAllData=true) should not be used in Apex unit tests because it opens up the existing database data for unexpected modification by tests');
		apexRuleMessages.put('ApexUnitTestClassShouldHaveAsserts', 'Apex unit test classes should have at least one System.assert() or assertEquals() or AssertNotEquals() call');
		apexRuleMessages.put('ApexSharingViolations', 'Apex classes should declare a sharing model if DML or SOQL is used');
		apexRuleMessages.put('ApexInsecureEndpoint', 'Apex callouts should use encrypted communication channels');
		apexRuleMessages.put('ApexCSRF', 'Avoid making DML operations in Apex class constructor/init method');
		apexRuleMessages.put('ApexOpenRedirect', 'Apex classes should safely redirect to a known location');
		apexRuleMessages.put('ApexSOQLInjection', 'Apex classes should escape variables merged in DML query');
		apexRuleMessages.put('ApexXSSFromURLParam', 'Apex classes should escape Strings obtained from URL parameters');
		apexRuleMessages.put('ApexXSSFromEscapeFalse', 'Apex classes should escape addError strings');
		apexRuleMessages.put('ApexBadCrypto', 'Apex Crypto should use random IV/key');
		apexRuleMessages.put('ApexCRUDViolation', 'Check for access permissions before a SOQL/SOSL/DML operation');
		apexRuleMessages.put('ApexDangerousMethods', 'Disabling CRUD security is unreliable. Calling System.debug passing sensitive data as parameter, which could lead to exposure of private data.');
		apexRuleMessages.put('ApexSuggestUsingNamedCred', 'Hardcoded credentials in requests to an endpoint are hard to mantain by being mixed in application code');
		apexRuleMessages.put('ForLoopsMustUseBraces', 'Avoid using \'for\' statements without using curly braces.');
		apexRuleMessages.put('IfElseStmtsMustUseBraces', 'Avoid using if..else statements without using curly braces.');
		apexRuleMessages.put('IfStmtsMustUseBraces', 'Avoid using if statements without using curly braces.');
		apexRuleMessages.put('WhileLoopsMustUseBraces', 'Avoid using \'while\' statements without using curly braces.');
    }

	public static void generateDefaultRuleSet () {

		apexRules = new List<Static_Code_Analysis_Rule__c>();

		for (String ruleName: Utilities.getPicklistValues(Settings.ns + 'Static_Code_Analysis_Rule__c',Settings.ns + 'Rule_Name__c')) {
			System.Debug('Rule found: ' + ruleName);
			Static_Code_Analysis_Rule__c rule = new Static_Code_Analysis_Rule__c();
			rule.Static_Code_Analysis_Settings__c = scaSettingsId;
			rule.Rule_Name__c = ruleName;
			rule.Priority__c = '3';
			rule.Message__c = apexRuleMessages.get(ruleName);
			apexRules.add(rule);
		}
		
		Utilities.Secure_DML([SELECT Id FROM Static_Code_Analysis_Rule__c WHERE Static_Code_Analysis_Settings__c = :scaSettingsId], Utilities.DML_Action.DEL, schema.Sobjecttype.Static_Code_Analysis_Settings__c);    
		Utilities.Secure_DML(apexRules, Utilities.DML_Action.INS, schema.Sobjecttype.Static_Code_Analysis_Rule__c); 

		ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, Label.DEFAULT_RULESET_GENERATED));
	}

	public PageReference Back () {

		return new PageReference('/'+ scaSettingsId);
	}
}