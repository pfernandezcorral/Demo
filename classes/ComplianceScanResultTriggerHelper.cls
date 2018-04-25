public without sharing class ComplianceScanResultTriggerHelper {

	public static Map<Id, Compliance_Scan_Result__c> scanResultSeverityFindingsMap;
	public static Map<Id, Compliance_Scan_Result__c> scanResultActionFindingsMap;
	public static Map<Id, Org__c> orgMap;
    public static Map<Id, Environment__c> envMap;
    public static Map<Id, User_Story__c> userStoryMap;
    public static Map<Id, Git_Backup__c> gitBackupMap;
    public static Map<Id, Deployment__c> deploymentMap; 
	
	public static void prepareData(List<SObject> records){
		orgMap = new Map<Id, Org__c>();
        envMap = new Map<Id, Environment__c>();
        userStoryMap = new Map<Id, User_Story__c>();
        gitBackupMap = new Map<Id, Git_Backup__c>();
        deploymentMap = new Map<Id, Deployment__c>();
		
        Set<Id> orgIds = new Set<Id>();
        Set<Id> envIds = new Set<Id>();
        Set<Id> userStoryIds = new Set<Id>();
        Set<Id> gitBackupIds = new Set<Id>();
        Set<Id> deploymentIds = new Set<Id>();
        Set<Id> scanResultIds = new Set<Id>();

    	for(SObject so : records) {
    		Compliance_Scan_Result__c scanResult = (Compliance_Scan_Result__c)so;
            scanResultIds.add(scanResult.Id);

            if(scanResult.Org_Credential__c != null) {
            	orgIds.add(scanResult.Org_Credential__c);
            }
            if(scanResult.Environment__c != null) {
            	envIds.add(scanResult.Environment__c);
            }
            if(scanResult.User_Story__c != null) {
            	userStoryIds.add(scanResult.User_Story__c);
            }
            if(scanResult.Git_Snapshot__c != null) {
            	gitBackupIds.add(scanResult.Git_Snapshot__c);
            }
            if(scanResult.Deployment__c != null) {
            	deploymentIds.add(scanResult.Deployment__c);
            }
    	}

        if(!Trigger.isDelete) {
            orgMap = new Map<Id, Org__c>([SELECT Id, Compliance_Status__c, Environment__c, Last_Compliance_Scan_Date__c, (SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Results__r ORDER BY CreatedDate DESC LIMIT 1) FROM Org__c WHERE Id IN :orgIds]);
            for(Org__c org : orgMap.values()) {
                envIds.add(org.Environment__c);
            }
        	envMap = new Map<Id, Environment__c>([SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c, (SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Results__r ORDER BY CreatedDate DESC LIMIT 1) FROM Environment__c WHERE Id IN :envIds]);
            userStoryMap = new Map<Id, User_Story__c>([SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c, (SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Results__r ORDER BY CreatedDate ASC LIMIT 1) FROM User_Story__c WHERE Id IN :userStoryIds]);
            gitBackupMap = new Map<Id, Git_Backup__c>([SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c, (SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Results__r ORDER BY CreatedDate DESC LIMIT 1) FROM Git_Backup__c WHERE Id IN :gitBackupIds]);
            deploymentMap = new Map<Id, Deployment__c>([SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c, (SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Results__r ORDER BY CreatedDate DESC LIMIT 1) FROM Deployment__c WHERE Id IN :deploymentIds]);
        } else {
            orgMap = new Map<Id, Org__c>([SELECT Id, Compliance_Status__c, Environment__c, Last_Compliance_Scan_Date__c, (SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Results__r WHERE Id NOT IN :scanResultIds ORDER BY CreatedDate DESC LIMIT 1) FROM Org__c WHERE Id IN :orgIds]);
            for(Org__c org : orgMap.values()) {
                envIds.add(org.Environment__c);
            }
            envMap = new Map<Id, Environment__c>([SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c, (SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Results__r WHERE Id NOT IN :scanResultIds ORDER BY CreatedDate DESC LIMIT 1) FROM Environment__c WHERE Id IN :envIds]);
            userStoryMap = new Map<Id, User_Story__c>([SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c, (SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Results__r WHERE Id NOT IN :scanResultIds ORDER BY CreatedDate DESC LIMIT 1) FROM User_Story__c WHERE Id IN :userStoryIds]);
            gitBackupMap = new Map<Id, Git_Backup__c>([SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c, (SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Results__r WHERE Id NOT IN :scanResultIds ORDER BY CreatedDate DESC LIMIT 1) FROM Git_Backup__c WHERE Id IN :gitBackupIds]);
            deploymentMap = new Map<Id, Deployment__c>([SELECT Id, Compliance_Status__c, Last_Compliance_Scan_Date__c, (SELECT Id, CreatedDate, Status__c FROM Compliance_Scan_Results__r WHERE Id NOT IN :scanResultIds ORDER BY CreatedDate DESC LIMIT 1) FROM Deployment__c WHERE Id IN :deploymentIds]);
        }        
    }

	public static void prepareSummaryData(List<SObject> records) {
    	System.debug('prepareSummaryData');
        Set<Id> scanResultIds = new Set<Id>();
    	for(SObject so : records) {
            scanResultIds.add(so.Id);
        }

        scanResultSeverityFindingsMap = new Map<Id, Compliance_Scan_Result__c>();
        scanResultActionFindingsMap = new Map<Id, Compliance_Scan_Result__c>();
    	scanResultSeverityFindingsMap = new Map<Id, Compliance_Scan_Result__c>([SELECT Id, Highest_Severity__c, (SELECT Id, Compliance_Rule__r.Severity__c FROM Compliance_Findings__r ORDER BY Compliance_Rule__r.Severity__c LIMIT 1) FROM Compliance_Scan_Result__c WHERE Id IN :scanResultIds]);
    	scanResultActionFindingsMap = new Map<Id, Compliance_Scan_Result__c>([SELECT Id, Highest_Rule_Action__c, (SELECT Id, Compliance_Rule__r.Action__c FROM Compliance_Findings__r ORDER BY Compliance_Rule__r.Action__c LIMIT 1) FROM Compliance_Scan_Result__c WHERE Id IN :scanResultIds]);
    }

	public static void updateComplianceFields(Compliance_Scan_Result__c scanResult) {
        System.debug('### updateComplianceFields');
        System.debug('### scanResult: '+scanResult);
		if(scanResult.Org_Credential__c != null && orgMap.get(scanResult.Org_Credential__c) != null) {
            Org__c org = orgMap.get(scanResult.Org_Credential__c);
            if(orgMap.get(scanResult.Org_Credential__c).Compliance_Scan_Results__r.size() > 0) {
                if(org.Last_Compliance_Scan_Date__c != orgMap.get(scanResult.Org_Credential__c).Compliance_Scan_Results__r[0].CreatedDate) {
                    org.Last_Compliance_Scan_Date__c = orgMap.get(scanResult.Org_Credential__c).Compliance_Scan_Results__r[0].CreatedDate;
                }
                if(org.Compliance_Status__c != orgMap.get(scanResult.Org_Credential__c).Compliance_Scan_Results__r[0].Status__c) {
                    org.Compliance_Status__c = orgMap.get(scanResult.Org_Credential__c).Compliance_Scan_Results__r[0].Status__c;
                }
            } else {
                org.Last_Compliance_Scan_Date__c = null;
                org.Compliance_Status__c = '';
            }
            Utilities.Secure_DML(org, Utilities.DML_Action.UPD, schema.Sobjecttype.Org__c);
        }

        if(scanResult.Environment__c != null && envMap.get(scanResult.Environment__c) != null) {
            Environment__c env = envMap.get(scanResult.Environment__c);
            if(envMap.get(scanResult.Environment__c).Compliance_Scan_Results__r.size() > 0) {
                System.debug('### *** env.Last_Compliance_Scan_Date__c: '+env.Last_Compliance_Scan_Date__c);
                System.debug('### *** envMap.get(scanResult.Environment__c).Compliance_Scan_Results__r[0].CreatedDate: '+envMap.get(scanResult.Environment__c).Compliance_Scan_Results__r[0].CreatedDate);
                if(env.Last_Compliance_Scan_Date__c != envMap.get(scanResult.Environment__c).Compliance_Scan_Results__r[0].CreatedDate) {
                    env.Last_Compliance_Scan_Date__c = envMap.get(scanResult.Environment__c).Compliance_Scan_Results__r[0].CreatedDate;
                }
                if(env.Compliance_Status__c != envMap.get(scanResult.Environment__c).Compliance_Scan_Results__r[0].Status__c) {
                    env.Compliance_Status__c = envMap.get(scanResult.Environment__c).Compliance_Scan_Results__r[0].Status__c;
                }
            } else {
                env.Last_Compliance_Scan_Date__c = null;
                env.Compliance_Status__c = '';
            }
            Utilities.Secure_DML(env, Utilities.DML_Action.UPD, schema.Sobjecttype.Environment__c);
        }

		if(scanResult.User_Story__c != null && userStoryMap.get(scanResult.User_Story__c) != null) {			
            User_Story__c userStory = userStoryMap.get(scanResult.User_Story__c);
            if(userStoryMap.get(scanResult.User_Story__c).Compliance_Scan_Results__r.size() > 0) {
                if(userStory.Last_Compliance_Scan_Date__c != userStoryMap.get(scanResult.User_Story__c).Compliance_Scan_Results__r[0].CreatedDate) {
                    userStory.Last_Compliance_Scan_Date__c = userStoryMap.get(scanResult.User_Story__c).Compliance_Scan_Results__r[0].CreatedDate;
                }
                if(userStory.Compliance_Status__c != userStoryMap.get(scanResult.User_Story__c).Compliance_Scan_Results__r[0].Status__c) {
                    userStory.Compliance_Status__c = userStoryMap.get(scanResult.User_Story__c).Compliance_Scan_Results__r[0].Status__c;
                }
            } else {
                userStory.Last_Compliance_Scan_Date__c = null;
                userStory.Compliance_Status__c = '';
            }
            Utilities.Secure_DML(userStory, Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story__c);
		}

		if(scanResult.Git_Snapshot__c != null && gitBackupMap.get(scanResult.Git_Snapshot__c) != null) {            
            Git_Backup__c gitBackup = gitBackupMap.get(scanResult.Git_Snapshot__c);
            if(gitBackupMap.get(scanResult.Git_Snapshot__c).Compliance_Scan_Results__r.size() > 0) {
                if(gitBackup.Last_Compliance_Scan_Date__c != gitBackupMap.get(scanResult.Git_Snapshot__c).Compliance_Scan_Results__r[0].CreatedDate) {
                    gitBackup.Last_Compliance_Scan_Date__c = gitBackupMap.get(scanResult.Git_Snapshot__c).Compliance_Scan_Results__r[0].CreatedDate;
                }
                if(gitBackup.Compliance_Status__c != gitBackupMap.get(scanResult.Git_Snapshot__c).Compliance_Scan_Results__r[0].Status__c) {
                    gitBackup.Compliance_Status__c = gitBackupMap.get(scanResult.Git_Snapshot__c).Compliance_Scan_Results__r[0].Status__c;
                }
            } else {
                gitBackup.Last_Compliance_Scan_Date__c = null;
                gitBackup.Compliance_Status__c = '';
            }
            Utilities.Secure_DML(gitBackup, Utilities.DML_Action.UPD, schema.Sobjecttype.Git_Backup__c); 
		}

        if(scanResult.Deployment__c != null && deploymentMap.get(scanResult.Deployment__c) != null) {
            Deployment__c deployment = deploymentMap.get(scanResult.Deployment__c);

            if(deploymentMap.get(scanResult.Deployment__c).Compliance_Scan_Results__r.size() > 0) {
                if(deployment.Last_Compliance_Scan_Date__c != deploymentMap.get(scanResult.Deployment__c).Compliance_Scan_Results__r[0].CreatedDate) {
                    deployment.Last_Compliance_Scan_Date__c = deploymentMap.get(scanResult.Deployment__c).Compliance_Scan_Results__r[0].CreatedDate;
                } 
                if(deployment.Compliance_Status__c != deploymentMap.get(scanResult.Deployment__c).Compliance_Scan_Results__r[0].Status__c) {
                    deployment.Compliance_Status__c = deploymentMap.get(scanResult.Deployment__c).Compliance_Scan_Results__r[0].Status__c;
                } 
            } else {
                deployment.Last_Compliance_Scan_Date__c = null;
                deployment.Compliance_Status__c = '';
            }
            Utilities.Secure_DML(deployment, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment__c);    
        }
	}

	public static void updateComplianceScanSummaryFields(Compliance_Scan_Result__c scanResult) {
		System.debug('### Compliance Scan Result: '+scanResult);
		if(scanResultSeverityFindingsMap.get(scanResult.Id) != null && scanResultSeverityFindingsMap.get(scanResult.Id).Compliance_Findings__r.size() > 0) {
			String highestSeverity = scanResultSeverityFindingsMap.get(scanResult.Id).Compliance_Findings__r[0].Compliance_Rule__r.Severity__c;
			System.debug('### HighestSeverity: '+highestSeverity);
			scanResult.Highest_Severity__c = highestSeverity;
		}
		if(scanResultActionFindingsMap.get(scanResult.Id) != null && scanResultActionFindingsMap.get(scanResult.Id).Compliance_Findings__r.size() > 0) {
			String highestRuleAction = scanResultActionFindingsMap.get(scanResult.Id).Compliance_Findings__r[0].Compliance_Rule__r.Action__c;
			System.debug('### HighestRuleAction: '+highestRuleAction);
			scanResult.Highest_Rule_Action__c = highestRuleAction;
		}
	}
}