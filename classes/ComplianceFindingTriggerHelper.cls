public with sharing class ComplianceFindingTriggerHelper {
	
	public static void updateComplianceScanResults() {
		Set<Id> scanResultIds = new Set<Id>();

		if(Trigger.New != null) {
			for(SObject so : Trigger.New) {
				Compliance_Finding__c finding = (Compliance_Finding__c)so;
	            scanResultIds.add(finding.Compliance_Scan_Result__c);
	        }
		}

		if(Trigger.isDelete) {
			for(SObject so : Trigger.Old) {
				Compliance_Finding__c finding = (Compliance_Finding__c)so;
	            scanResultIds.add(finding.Compliance_Scan_Result__c);
	        }
		}

		List<Compliance_Scan_Result__c> scanResults = [SELECT Id FROM Compliance_Scan_Result__c WHERE Id IN :scanResultIds];
		System.debug('### Compliance Scan Results to Update:'+scanResults);
		Utilities.Secure_DML(scanResults, Utilities.DML_Action.UPD, schema.Sobjecttype.Compliance_Scan_Result__c);
	}
}