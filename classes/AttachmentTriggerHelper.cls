public without sharing class AttachmentTriggerHelper {

    public static Set<String> supportedPrefixes = new Set<String>();
    public static Set<String> supportedNames = new Set<String>();
    public static Set<String> supportedMetadataNames = new Set<String>();

    public static List<Copado_Notification__c> notifications = new List<Copado_Notification__c>();
    public static List<Copado_Notification__c> upserts = new List<Copado_Notification__c>();
    public static List<Id> notificationFinishedIds = new List<Id>();

    public static Map<String, Selenium_Locator_Reference__c> locatorReferences = new Map<String, Selenium_Locator_Reference__c>();
    public static Map<String, Selenium_Locator__c> locators = new Map<String, Selenium_Locator__c>();
    public static Set<String> delete_locatorReferences = new Set<String>();
    public static Set<Id> userstoryIds = new Set<Id>();
    public static map<Id, Attachment> scaIdWithAtt = new map<Id, Attachment>();
    public static Map<Id, Id> deploymentFlowMap = new Map<Id, Id>(); // Deployment_Flow__c.Id, Deployment_Flow_Step__c.Id
    public static Map<Id, Deployment_Flow_Step__c> deploymentFlowStepMap = new Map<Id, Deployment_Flow_Step__c>();

    public static String DFS_INSYNC = 'In sync';

    public static boolean skipCopadoTrigger() {
        try {
            //this is to check if customer running user has access to Copado package
            return !UserInfo.isCurrentUserLicensed('copado');
        } catch (Exception e) {
            //this is BP or Patch org, with namespace but not package installed
            if (e.getMessage().contains('prefix not found'))return false;
        }
        return false;
    }
    public static void prepareData() {
        //prevent non copado users for failing the trigger without access to Copado entities
        if (skipCopadoTrigger())return;

        supportedPrefixes.add(Deployment_Job__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Snapshot_Difference__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Apex_Test_Result__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Org__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Build_Task__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Git_Backup__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(User_Story__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Git_Repository__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Promotion__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Deployment_Flow_Step__c.SObjectType.getDescribe().getKeyPrefix());
        supportedPrefixes.add(Deployment_Flow__c.SObjectType.getDescribe().getKeyPrefix());

        supportedNames.add('DEPLOYMENT_STATUS_COPADO');
        supportedNames.add('PROGRESS_STATUS_COPADO');
        supportedNames.add('TEST_PROGRESS_STATUS_COPADO');

        supportedMetadataNames.add('MetaData');
        supportedMetadataNames.add('Git MetaData');
        supportedMetadataNames.add('Delete MetaData');
        supportedMetadataNames.add('result.json');

        List<SObject> records = new List<SObject>();
        if (Trigger.isInsert || Trigger.isUpdate)records = Trigger.new;
        if (Trigger.isDelete)records = Trigger.old;
        for (SObject o : records) {
            Attachment att = (Attachment)o;
            if (att.ParentId != null) {
                String parentId = att.ParentId;
                if ((parentId.substring(0, 3) == User_Story__c.SObjectType.getDescribe().getKeyPrefix()) && supportedMetadataNames.contains(att.Name)) {
                    userStoryIds.add(parentId);
                } else if ((parentId.substring(0, 3) == Deployment_Flow__c.SObjectType.getDescribe().getKeyPrefix()) && supportedMetadataNames.contains(att.Name)) {
                    deploymentFlowMap.put(parentId, null);
                } else if ((parentId.substring(0, 3) == Deployment_Flow_Step__c.SObjectType.getDescribe().getKeyPrefix()) && supportedMetadataNames.contains(att.Name)) {
                    deploymentFlowStepMap.put(parentId, new Deployment_Flow_Step__c());
                }
            }
        }

        if(!deploymentFlowStepMap.isEmpty() || !deploymentFlowMap.isEmpty()) {
            for (Deployment_Flow_Step__c flowStep : [SELECT Id, Name, Commits_Ahead__c, Commits_Behind__c, Deployment_Flow__c, Destination_Branch__c, Merge_Auto_Resolved_Files__c, Pull_Auto_Resolved_Files__c, Sync_Merge_State__c, Sync_Pull_State__c FROM Deployment_Flow_Step__c WHERE Id IN :deploymentFlowStepMap.keySet() OR Deployment_Flow__c IN :deploymentFlowMap.keySet()]) {
                System.debug('### Found the flowStep');
                deploymentFlowMap.put(flowStep.Deployment_Flow__c, flowStep.Id);
                deploymentFlowStepMap.put(flowStep.Id, flowStep);
            }
        }
    }
    public static void prepareAfterData() {
        //prevent non copado users for failing the trigger without access to Copado entities
        if (skipCopadoTrigger()) {
            return;
        }
        //Get SCARecordIds when they are inserted
        if (Trigger.isInsert) {
            scaIdWithAtt = new map<Id, Attachment>();
            for (SObject o : Trigger.new) {
                Attachment a = (Attachment)o;
                if (a.Name == 'SCAreport.xml') {
                    scaIdWithAtt.put(a.ParentId, a);
                }
            }
        }
    }


    public static void createOrFinishCopadoNotification(Attachment a, boolean doFinish) {
        String aId = a.parentId;
        System.debug('###createOrFinishCopadoNotification: ' + a.Id + ' ParentId=' + aId + ' supportedPrefixes=' + supportedPrefixes + ' a.Name=' + a.Name);
        if (supportedPrefixes.contains(aId.substring(0, 3)) && supportedNames.contains(a.Name)) {
            Map<String, Object> fullMap;
            String body;
            try {
                body = a.Body.toString();
                fullMap = (Map<String, Object>)JSON.deserializeUntyped(body);
            } catch (Exception e) {
                System.debug('###ERROR TRYING TO PARSE ATTACHMENT BODY: ' + (a.Body != null ? a.Body.toString() : null));
            }
            Copado_Notification__c cn = new Copado_Notification__c();
            cn.Name = a.Name;
            cn.ParentId__c = a.ParentId;
            cn.AttachmentId__c = a.Id;
            if (fullMap != null) {
                cn.Parent2Id__c = (fullMap.get('parent2id') != null ? (String)fullMap.get('parent2id') : null);
                cn.Message__c = (body.length() <= 255) ? body : null;
                if (String.isNotBlank((String)fullMap.get('type')))
                    cn.Type__c = (String)fullMap.get('type');
            }
            if (doFinish) {
                cn.isFinished__c = true;
                // try to delete the attachment (?)
            }
            upserts.add(cn);
            System.debug('###create finish? ' + doFinish + ' cn=' + cn);
        }

    }

    public static void upsertCopadoNotifications() {
        system.debug('##### FINALLY Upsert Notifications : ' + AttachmentTriggerHelper.upserts.size());
        try {
            Database.upsert(AttachmentTriggerHelper.upserts, Copado_Notification__c.AttachmentId__c, false);
        } catch (Exception e) {
            system.debug(e);
        }
    }

    public static void processSeleniumLocators(Attachment a, boolean isDelete) {
        System.debug(loggingLevel.Error, '*** a.Name: ' + a.Name);
        if (a.Name.startsWith('Copado.SeleniumTestCase')) {
            System.debug(loggingLevel.Error, '*** in selenium test case attachment handler: ');
            String version = [Select Version__c FROM Selenium_Test_Case__c WHERE Id = :a.ParentId].Version__c;
            Map<String, Object> fullMap = (Map<String, Object>)JSON.deserializeUntyped(a.Body.toString());
            List<Object> commands = (List<Object>)fullMap.get('commands');
            System.debug(loggingLevel.Error, '*** commands: '+commands);
            if (commands == null || commands.size() == 0) {
                return;
            }
            Set<String> locator_ids = new Set<String>();
            for (Object o : commands) {
                Map<String, Object> cmd = (Map<String, Object>)o;
                String locator = (String)cmd.get('target');
                if (locator == null || locator == 'null')continue;
                String page = '';
                Map<String, Object> context = (Map<String, Object>)cmd.get('context');
                if (context != null)
                    page = (String)context.get('pageref');

                // user-defined locators ( with locator_id ) are treated separatedly.
                if (locator.toLowerCase().startsWith('{!locator.') && locator.endsWith('}')) {
                    locator_ids.add( locator.substring(10, locator.length() - 1) );
                } else {
                    String locatorExtId = getLocatorExternalID(page, locator);
                    String referenceExtId = locatorExtId + a.ParentId;
                    if (!isDelete) {
                        //System.debug('- item  '+locatorExtId+' referenceExtId='+referenceExtId+' locator='+locator);
                        locators.put(locatorExtId, new Selenium_Locator__c(Page__c = page,
                                     Locator__c = locator,
                                     External_ID__c = locatorExtId));
                        locatorReferences.put(referenceExtId, new Selenium_Locator_Reference__c(
                                                  Selenium_Locator__r = new Selenium_Locator__c(External_ID__c = locatorExtId),
                                                  Selenium_Test_Case__c = a.ParentId,
                                                  External_ID__c = referenceExtId
                                              ));
                    } else {
                        delete_locatorReferences.add(referenceExtId);
                    }
                }
            }

            // lookup the named locators, and create the corresponding references
            List<Selenium_Locator__c> named_locators = [SELECT Id, Locator_ID__c, External_ID__c, Locator__c FROM Selenium_Locator__c WHERE Locator_ID__c in :locator_ids];
            for (Selenium_Locator__c named_locator : named_locators ) {
                String referenceExtId = named_locator.External_ID__c + a.ParentId;
                //System.debug('- named '+referenceExtId+' '+named_locator.Locator__c);
                if (!isDelete) {
                    locatorReferences.put(referenceExtId, new Selenium_Locator_Reference__c(
                                              Selenium_Locator__c = named_locator.Id,
                                              Selenium_Test_Case__c = a.ParentId,
                                              External_ID__c = referenceExtId
                                          ));
                } else {
                    delete_locatorReferences.add(referenceExtId);
                }
            }
            System.debug('locatorReferences=' + locatorReferences);
        } else {
            System.debug('**** attachment ignored ' + a.Name);
        }
    }

    public static void persistSeleniumLocators() {
        try {
            system.debug('##### FINALLY Upsert Locators: ' + AttachmentTriggerHelper.locators.size());
            Database.UpsertResult[] resLocs = Database.upsert(AttachmentTriggerHelper.locators.values(), Selenium_Locator__c.External_ID__c, false);
            for (Database.UpsertResult r : resLocs) {
                if (!r.isSuccess())System.debug('*** ERROR: ' + r.getErrors()[0].getMessage());
            }
            system.debug('##### FINALLY Upsert Locator References: ' + AttachmentTriggerHelper.locatorReferences.size());
            Database.UpsertResult[] resRefs = Database.upsert(AttachmentTriggerHelper.locatorReferences.values(), Selenium_Locator_Reference__c.External_ID__c, false);
            for (Database.UpsertResult r : resRefs) {
                if (!r.isSuccess())System.debug('*** ERROR: ' + r.getErrors()[0].getMessage());
            }
            if(!delete_locatorReferences.isEmpty()) {
                Utilities.Secure_DML([select id from Selenium_Locator_Reference__c where External_ID__c in :delete_locatorReferences], Utilities.DML_Action.DEL, schema.Sobjecttype.Selenium_Locator_Reference__c);
            }
        } catch (Exception e) {
            system.debug('**** persistSeleniumLocators error: '+e);
        }
    }
    public static String getLocatorExternalID(String page, String target) {
        String extId = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(page + target)));
        System.debug('**** DEBUG - input ' + page + ' + ' + target + ' = ' + extId);
        return extId;
    }
    public static void processExternalCIDeploymentJobs() {
        Map<String, String> djStats = new Map<String, String>();
        if(Trigger.new == null){
            return;
        }
        for (Attachment att : (List<Attachment>)Trigger.new) {
            if (att.Name.Contains('.json') && att.Name.Contains(Deployment_Job__c.SObjectType.getDescribe().getKeyPrefix()) && String.valueOf(att.ParentId).contains(Deployment__c.SObjectType.getDescribe().getKeyPrefix())) {
                try {
                    System.debug(loggingLevel.Error, '*** att.Body: ' + att.Body);
                    List<Object> resultsObjectList = (List<Object>)JSON.deserializeUntyped(att.Body.ToString());
                    Boolean isSuccess = true;
                    Boolean isFinished = false;
                    for (Object obj : resultsObjectList) {
                        Map<String, Object> resultItems = (Map<String, Object>)obj;
                        Map<String, Object> stats = (Map<String, Object>)JSON.deserializeUntyped(String.valueOf(resultItems.get('m')));
                        System.debug(loggingLevel.Error, '*** att.Name: ' + att.Name);
                        System.debug(loggingLevel.Error, '*** status: ' + stats.get('status'));
                        djStats.put(att.Name.replace('.json', ''), String.valueOf(stats.get('status')));
                    }
                } catch (Exception e) {
                    System.debug('processExternalCIDeploymentJobs Exception Message >>> ' + e.getMessage());
                }
            }
        }
        System.debug(loggingLevel.Error, '*** djStats: ' + djStats);
        List<Deployment_Job__c> deploymentJobsToUpdate = new List<Deployment_Job__c>();
        for (String djId : djStats.keySet()) {
            Deployment_Job__c dj = new Deployment_Job__c(
                Id = djId,
                External_Status__c = djStats.get(djId)
            );
            deploymentJobsToUpdate.add(dj);
        }
        System.debug(loggingLevel.Error, '*** deploymentJobsToUpdate: ' + deploymentJobsToUpdate);
        if (!deploymentJobsToUpdate.isEmpty()) {
            Utilities.Secure_DML(deploymentJobsToUpdate, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment_Job__c);
        }
    }
    public static void processUserStoryMetadata(Attachment a) {
        if (userstoryIds.contains(a.parentId)) {
            System.debug('##### Start MetadataIndexJob');
            IndexMetadataJob imJob = new IndexMetadataJob();
            imJob.userstoryId = a.parentId;
            Id batchJobId = database.executebatch(imJob);
        }
    }
    public static void processDeploymentFlow(Attachment att) {
        try {
            if (att.parentId != null) {
                String parentId = att.parentId;
                if (att.Name == 'result.json' && parentId.substring(0, 3) == Deployment_Flow__c.SObjectType.getDescribe().getKeyPrefix() && deploymentFlowMap.get(att.parentId) != null) {
                    System.debug('### ProcessDeploymentFlow');
                    String body = EncodingUtil.base64Decode(EncodingUtil.base64Encode(att.Body)).toString();
                    List<Object> attachmentSteps = (List<Object>)JSON.deserializeUntyped(body);
                    System.debug('attachmentSteps: ' + attachmentSteps);

                    for (Object attachmentStep : attachmentSteps) {
                        // Determine which deployment flow step this is
                        Map<String, Object> attachmentStepAttributes = (Map<String, Object>)attachmentStep;
                        System.debug('### attachmentStepAttributes: ' + attachmentStepAttributes);
                        if (deploymentFlowStepMap.get((String)attachmentStepAttributes.get('id')) != null) {
                            Deployment_Flow_Step__c step = deploymentFlowStepMap.get((String)attachmentStepAttributes.get('id'));
                            System.debug('### stepBeforeBeingUpdatedByAttachment: ' + step);

                            // Last Merge Base
                            if ((attachmentStepAttributes.get('mergeTimestamp') != null)) {
                                try {
                                    String unixMergeTimestamp = (String)attachmentStepAttributes.get('mergeTimestamp');
                                    if (unixMergeTimestamp != null || unixMergeTimestamp != '') step.Last_Merge_Base__c = DateTime.newinstance(Long.valueOf(unixMergeTimestamp));
                                } catch (Exception e) {
                                    System.debug(e);
                                }
                            }

                            // Destination Branch
                            try {
                                step.Destination_Branch__c = (String)attachmentStepAttributes.get('destinationBranch');
                            } catch (Exception e) {
                                System.debug(e);
                            }

                            // Commits Ahead and Behind
                            Integer newCommitsAhead = 0;
                            Integer newCommitsBehind = 0;

                            try {
                                if (attachmentStepAttributes.get('commitsAhead') != null) newCommitsAhead = Integer.valueOf((Decimal)attachmentStepAttributes.get('commitsAhead'));
                                if (attachmentStepAttributes.get('commitsBehind') != null) newCommitsBehind = Integer.valueOf((Decimal)attachmentStepAttributes.get('commitsBehind'));
                            } catch (Exception e) {
                                System.debug(e);
                            }

                            if (step.Commits_Ahead__c > 0 && newCommitsAhead == 0) {
                                step.Last_Merge_CBM_Sync__c = Datetime.now();
                            }
                            if (step.Commits_Behind__c > 0 && newCommitsBehind == 0) {
                                step.Last_Pull_CBM_Sync__c = Datetime.now();
                            }

                            step.Commits_Ahead__c = 0;
                            step.Commits_Behind__c = 0;
                            if (newCommitsAhead != null) step.Commits_Ahead__c = newCommitsAhead;
                            if (newCommitsBehind != null) step.Commits_Behind__c = newCommitsBehind;

                            // Merge and Pull Validation Success
                            if (step.Commits_Ahead__c == 0) step.Sync_Merge_State__c = DFS_INSYNC;
                            if (step.Commits_Behind__c == 0) step.Sync_Pull_State__c = DFS_INSYNC;

                            // Merge and Pull Auto Resolved Files
                            if (attachmentStepAttributes.get('filesMergedConflictAhead') != null) {
                                List<Object> filesMergedConflictAhead = (List<Object>)attachmentStepAttributes.get('filesMergedConflictAhead');
                                try {
                                    step.Merge_Auto_Resolved_Files__c = String.join(filesMergedConflictAhead, ',');
                                    System.debug('### filesMergedConflictAhead: ' + step.Merge_Auto_Resolved_Files__c);
                                } catch (Exception e) {
                                    step.Merge_Auto_Resolved_Files__c = '';
                                    System.debug(e);
                                }
                            } else {
                                step.Merge_Auto_Resolved_Files__c = '';
                            }
                            if (attachmentStepAttributes.get('filesMergedConflictBehind') != null) {
                                List<Object> filesMergedConflictBehind = (List<Object>)attachmentStepAttributes.get('filesMergedConflictBehind');
                                try {
                                    step.Pull_Auto_Resolved_Files__c = String.join(filesMergedConflictBehind, ',');
                                    System.debug('### filesMergedConflictBehind: ' + step.Pull_Auto_Resolved_Files__c);
                                } catch (Exception e) {
                                    step.Pull_Auto_Resolved_Files__c = '';
                                    System.debug(e);
                                }
                            } else {
                                step.Pull_Auto_Resolved_Files__c = '';
                            }

                            if (step.Commits_Ahead__c == 0 && step.Commits_Behind__c == 0) {
                                step.Pull_Auto_Resolved_Files__c = '';
                                step.Merge_Auto_Resolved_Files__c = '';
                            }

                            System.debug('### stepAfterBeingUpdatedByAttachment: ' + step);
                            Utilities.Secure_DML(step, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment_Flow_Step__c);
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug(e);
        }
    }

    public static void processDeploymentFlowStep(Attachment att) {
        System.debug('### processDeploymentFlowStep: att=' + att);
        String parentId = att.parentId;
        if (parentId == null)
            return; // it might be badly created by java, and this is a before trigger.
        if (att.Body == null)
            return; // meaning the body was unchanged.

        if (att.Name == 'result.json' && parentId.substring(0, 3) == Deployment_Flow_Step__c.SObjectType.getDescribe().getKeyPrefix()) {
            String body = EncodingUtil.base64Decode(EncodingUtil.base64Encode(att.Body)).toString();
            Map<String, Object> attachmentStepAttributes = (Map<String, Object>)JSON.deserializeUntyped(body);
            Deployment_Flow_Step__c step = deploymentFlowStepMap.get(att.parentId);
            if (step != null) {
                if (attachmentStepAttributes.containsKey('mergeValidationSuccess'))
                    step.Sync_Merge_State__c = (Boolean)attachmentStepAttributes.get('mergeValidationSuccess')
                                               ? 'Validated' : 'Validation errors';
                if (step.Commits_Ahead__c == 0)
                    step.Sync_Merge_State__c = DFS_INSYNC;

                if (attachmentStepAttributes.containsKey('pullValidationSuccess'))
                    step.Sync_Pull_State__c = (Boolean)attachmentStepAttributes.get('pullValidationSuccess')
                                              ? 'Validated' : 'Validation errors';
                if (step.Commits_Behind__c == 0)
                    step.Sync_Pull_State__c = DFS_INSYNC;

                Utilities.Secure_DML(step, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment_Flow_Step__c);
                System.debug('### stepAfterBeingUpdatedByAttachment: ' + step);
            }
        }
    }
}