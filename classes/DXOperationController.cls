/**
 * Created by ferhatozsavran on 1/22/18.
 */

public with sharing class DXOperationController extends ScratchOrgWizardPageBase {

    public Map<String, String> dxOperationMap { get; set; }
    public Map<String, String> dxOperationDetailMap { get; set; }
    public Map<String, String> objectNameMap { get; set; }

    public String selectedActionName { get; set; }
    public String selectedOperation { get; set; }
    public String selectedOperationDataId { get; set; }
    public String selectedDeploymentId { get; set; }
    public String usName { get; set; }
    public String usId { get; set; }
    public String usOrgName { get; set; }
    public String usOrgId { get; set; }
    public String sourceOrgName { get; set; }
    public String sourceOrgId { get; set; }
    public String namespace { get; set; }
    public String dxDeploymentFlowMode { get; set; }
    public String dxDeploymentFlowGitRepo { get; set; }
    public String dxBranchName { get; set; }
    private String recordId;
    private String actionName;

    public Boolean enableActions { get; set; }
    public Boolean disableUserStorySelection { get; set; }
    public Boolean disableOperationPicklist { get; set; }
    public Boolean disableLoadMetadataPanel { get; set; }
    public Boolean disablePanels { get; set; }
    private Boolean enableDevHubOperation;
    private Boolean enableScratchOrgOperation;

    public ScratchOrgWizardComponentBase componentController { get; set; }

    public List<SelectOption> orgCredentials { get; set; }
    public List<SelectOption> operationList { get; set; }
    public List<SelectOption> deploymentList { get; set; }
    public transient List<Git_Org_Commit__c> snapshotCommitList { get; set; }
    public transient List<User_Story_Commit__c> userStoryCommitList { get; set; }
    public transient List<Artifact__c> artifactList { get; set; }
    public List<Org__c> activeScratchOrgList { get; set; }
    public List<Org__c> deletedScratchOrgList { get; set; }

    public Object metadataSourceType { get; set; }
    public Object metadataSource { get; set; }

    public PageReference pageRef { get; set; }

    public DXOperationController() {
        namespace = Settings.ns;
        disableUserStorySelection = false;
        disableOperationPicklist = false;
        disableLoadMetadataPanel = false;
        disablePanels = false;

        recordId = ApexPages.currentPage().getParameters().get('id');
        actionName = ApexPages.currentPage().getParameters().get('act');
        if (String.isNotBlank(recordId)) {
            Schema.sObjectType objectAPIName = ((Id) recordId).getSObjectType();

            enableDevHubOperation = false;
            enableScratchOrgOperation = false;
            if (String.valueOf(objectAPIName) == Settings.ns + 'Org__c') {
                selectedOperation = '0';
                orgCredentials();
                if (enableDevHubOperation) {
                    selectedOperation = '2';
                }
                if (enableScratchOrgOperation) {
                    selectedOperation = '1';
                }
                if (!enableScratchOrgOperation && !enableDevHubOperation) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.Scratch_Org_Operation_Expired_Warning + SfdxAPIHelper.DX_PROJECT_BRANCH + recordId.substring(3, 15)));
                    disablePanels = true;
                    return;
                }
                selectedOperationDataId = recordId;
            } else if (String.valueOf(objectAPIName) == Settings.ns + 'User_Story__c') {

                usId = recordId;
                if (!SfdxAPIHelper.isDXEnabledForUSDeploymentFlow(usId)) {
                    Apexpages.addMessage(new apexpages.Message(apexpages.severity.WARNING, SfdxAPIHelper.flowMessage));
                    disableUserStorySelection = false;
                    disablePanels = true;
                    return;
                }
                usName = [Select Name From User_Story__c Where Id = :recordId].Name;

                disableUserStorySelection = true;
                selectedOperation = '3';
            }
            populatePossibleActions();

            if (selectedOperation != '0') {
                disableOperationPicklist = true;
            }
        }
        availableOperations();

        if (String.isNotBlank(actionName)) {
            enableSelectedPanels();
        }
    }

    public override void setComponentController(ScratchOrgWizardComponentBase wizCompController) {
        componentController = (ScratchOrgWizardComponentBase) wizCompController;
    }

    public override ScratchOrgWizardComponentBase getMyComponentController() {
        return componentController;
    }

    public PageReference enableSelectedPanels() {
        selectedActionName = String.isNotBlank(ApexPages.currentPage().getParameters().get('actionName')) ? ApexPages.currentPage().getParameters().get('actionName') : actionName;
        if (String.isNotBlank(selectedActionName) && selectedActionName == 'main') {
            PageReference pr = Page.DXOperation;
            if (String.isNotBlank(recordId)) {
                pr.getParameters().put('id', recordId);
            }
            pr.setRedirect(true);
            return pr;
        } else if (String.isNotBlank(selectedActionName) && selectedActionName == 'ch') {
            if (String.isNotBlank(usId)) {
                retrieveUserStoryCommit();
            } else if (String.isNotBlank(selectedOperationDataId)) {
                retrieveSnapshotCommits();
            }
        } else if (String.isNotBlank(selectedActionName) && selectedActionName == 'mso' || String.isNotBlank(selectedActionName) && selectedActionName == 'ma') {
            orgCredentials();
        } else if (String.isNotBlank(selectedActionName) && selectedActionName == 'mdt' || String.isNotBlank(selectedActionName) && selectedActionName == 'mpt') {
            selectedOperationDataId = '-- None --';
        } else if (String.isNotBlank(selectedActionName) && (selectedActionName == 'lm' || selectedActionName == 'csous') && (String.isNotBlank(selectedOperationDataId) || String.isNotBlank(usId))) {
            List<Attachment> attachmentList = new List<Attachment>();
            if (String.isNotBlank(selectedOperationDataId) && selectedActionName != 'csous') {
                attachmentList = [Select Body From Attachment Where ParentId = :selectedOperationDataId And Name Like '%metadataSources%' Order By CreatedDate Desc Limit 1];

                String environmentId = [Select Environment__c From Org__c Where Id = :selectedOperationDataId].Environment__c;

                if (String.isNotBlank(environmentId)) {
                    List<Deployment_Flow_Step__c> deploymentFlowStep = new List<Deployment_Flow_Step__c>([Select Deployment_Flow__r.Git_Repository__c, Deployment_Flow__r.Copado_DX_Mode__c From Deployment_Flow_Step__c Where Source_Environment__c = :environmentId Limit 1]);
                    if (!deploymentFlowStep.isEmpty()) {
                        dxDeploymentFlowMode = deploymentFlowStep.get(0).Deployment_Flow__r.Copado_DX_Mode__c;
                        dxDeploymentFlowGitRepo = deploymentFlowStep.get(0).Deployment_Flow__r.Git_Repository__c;
                    }
                }
            } else if (String.isNotBlank(usId)) {
                String orgCredential = '';
                for (User_Story__c us : [Select Org_Credential__c From User_Story__c Where Id = :usId Limit 1]) {
                    orgCredential = us.Org_Credential__c;
                }
                if (selectedActionName == 'csous' && String.isNotBlank(orgCredential)) {
                    Apexpages.addMessage(new apexpages.Message(apexpages.severity.WARNING, Label.DX_US_ALREADY_HAS_AN_ORG));
                } else if (selectedActionName != 'csous') {
                    Org__c org = [Select Org_Type__c From Org__c Where Id = :orgCredential];
                    selectedOperationDataId = orgCredential;
                    if (String.isNotBlank(org.Org_Type__c) && !org.Org_Type__c.startsWithIgnoreCase('Scratch Org')) {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.Scratch_Org_Selection_Validation));
                        disableLoadMetadataPanel = true;
                        return null;
                    }
                    attachmentList = [Select Body From Attachment Where ParentId = :orgCredential And Name Like '%metadataSources%' Order By CreatedDate Desc Limit 1];
                }
            }

            if (!attachmentList.isEmpty()) {
                Map<String, Object> deserializedJsonMap = (Map<String, Object>) JSON.deserializeUntyped(attachmentList.get(0).Body.toString());
                metadataSourceType = deserializedJsonMap.containsKey('metadataSourceType') ? deserializedJsonMap.get('metadataSourceType') : '';
                metadataSource = deserializedJsonMap.containsKey('metadataSource') ? deserializedJsonMap.get('metadataSource') : '';

                if (metadataSourceType == 'branch' || metadataSourceType == 'org') {
                    String orgName = String.isNotBlank(selectedOperationDataId) ? [Select Name From Org__c Where Id = :selectedOperationDataId].Name : Label.DX_Operation_Load_Warning_Message1;
                    String orgTypeMessage = metadataSourceType == 'branch' ? ' branch. ' : ' org. ';
                    String eMessages = orgName + Label.DX_Operation_Load_Warning_Message2 + metadataSource + orgTypeMessage + Label.DX_Operation_Load_Warning_Message3;
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, eMessages));
                    disableLoadMetadataPanel = true;
                    return null;
                }
            }
        }
        return null;
    }

    public void resetDom() {
        enableActions = false;
        selectedOperationDataId = '-- None --';
        usId = null;
        usName = '';
        dxOperationMap = new Map<String, String>();
        dxOperationDetailMap = new Map<String, String>();
        if (selectedOperation == '1' || selectedOperation == '2') {
            orgCredentials();
        }

        if (selectedOperation == '4') {
            dxOperationMap.put(Label.DXOperation_ManageDefinitionTemplate, 'mdt');
            dxOperationDetailMap.put(Label.DXOperation_ManageDefinitionTemplate, Label.Definition_Template_Detail);
            dxOperationMap.put(Label.DXOperation_ManageProjectTemplate, 'mpt');
            dxOperationDetailMap.put(Label.DXOperation_ManageProjectTemplate, Label.Project_Template_Details);

            List<Schema.DescribeSObjectResult> dsrList = new List<Schema.DescribeSObjectResult>();
            dsrList.add(Schema.SObjectType.Org__c);
            dsrList.add(Schema.SObjectType.Artifact__c);
            Map<Schema.DescribeSObjectResult, SfdxAPIHelper.ObjectLevelSecurity> olsMap = SfdxAPIHelper.checkOLS(dsrList);

            if (olsMap.get(Schema.SObjectType.Artifact__c).accessible && olsMap.get(Schema.SObjectType.Org__c).accessible) {
                dxOperationMap.put(Label.DXOperation_ManageArtifacts, 'ma');
                dxOperationDetailMap.put(Label.DXOperation_ManageArtifacts, Label.Artifacts_Detail);
            }
            enableActions = true;
        }
    }

    public void populatePossibleActions() {
        dxOperationMap = new Map<String, String>();
        dxOperationDetailMap = new Map<String, String>();

        if (selectedOperation != '0') {
            enableActions = true;
        }

        if (selectedOperation == '3') {
            if (!SfdxAPIHelper.isDXEnabledForUSDeploymentFlow(usId)) {
                Apexpages.addMessage(new apexpages.Message(apexpages.severity.WARNING, SfdxAPIHelper.flowMessage));
                disableUserStorySelection = false;
                disablePanels = true;
                return;
            }

            if (String.isNotBlank(usId)) {
                String orgCredential = '';
                String orgType = '';
                String orgName = '';
                for (User_Story__c us : [Select Org_Credential__c, Org_Credential__r.Org_Type__c, Org_Credential__r.Name From User_Story__c Where Id = :usId Limit 1]) {
                    orgCredential = us.Org_Credential__c;
                    orgType = us.Org_Credential__c != null ? us.Org_Credential__r.Org_Type__c : '';
                    orgName = us.Org_Credential__c != null ? us.Org_Credential__r.Name : '';
                }

                if (String.isNotBlank(orgCredential) && String.isNotBlank(orgType) && orgType == 'Scratch Org') {
                    usOrgName = orgName;
                    usOrgId = orgCredential;
                    selectedOperationDataId = orgCredential;
                }
            }
            dxOperationMap.put(Label.DXOperation_CreateSO, 'csous');
            dxOperationDetailMap.put(Label.DXOperation_CreateSO, Label.Create_Scratch_Org_Detail);
        }

        if (selectedOperation == '2') {
            dxOperationMap.put(Label.DXOperation_ManageSOs, 'mso');
            dxOperationDetailMap.put(Label.DXOperation_ManageSOs, Label.Manage_Scratch_Org_Detail);
            dxOperationMap.put(Label.DXOperation_CreateSO, 'cso');
            dxOperationDetailMap.put(Label.DXOperation_CreateSO, Label.Create_Scratch_Org_Detail);
        }

        if (selectedOperation == '1') {
            List<Schema.DescribeSObjectResult> dsrList = new List<Schema.DescribeSObjectResult>();
            dsrList.add(Schema.SObjectType.Git_Repository__c);
            dsrList.add(Schema.SObjectType.Deployment_Flow_Step__c);
            Map<Schema.DescribeSObjectResult, SfdxAPIHelper.ObjectLevelSecurity> olsMap = SfdxAPIHelper.checkOLS(dsrList);

            if (olsMap.get(Schema.SObjectType.Git_Repository__c).accessible && olsMap.get(Schema.SObjectType.Deployment_Flow_Step__c).accessible) {
                dxOperationMap.put(Label.DXOperation_OrgStatus, 'gsos');
                dxOperationDetailMap.put(Label.DXOperation_OrgStatus, Label.Org_Status_Detail);
            }
        }

        if (selectedOperation == '1' || selectedOperation == '3') {

            if (selectedOperation == '1') {
                SfdxAPIHelper.ObjectLevelSecurity ols = SfdxAPIHelper.checkOLS(Schema.SObjectType.Git_Org_Commit__c);
                if (ols.accessible) {
                    dxOperationMap.put(Label.DXOperation_CommitHistory, 'ch');
                    dxOperationDetailMap.put(Label.DXOperation_CommitHistory, Label.Commit_History_Detail);
                    dxOperationMap.put(Label.DXOperation_LoadData, 'ld');
                    dxOperationDetailMap.put(Label.DXOperation_LoadData, Label.Optional_Configuration_Detail);
                }
            } else if (selectedOperation == '3') {
                SfdxAPIHelper.ObjectLevelSecurity ols = SfdxAPIHelper.checkOLS(Schema.SObjectType.User_Story_Commit__c);
                if (ols.accessible) {
                    dxOperationMap.put(Label.DXOperation_CommitHistory, 'ch');
                    dxOperationDetailMap.put(Label.DXOperation_CommitHistory, Label.Commit_History_Detail);
                    dxOperationMap.put(Label.DXOperation_LoadData, 'ld');
                    dxOperationDetailMap.put(Label.DXOperation_LoadData, Label.Optional_Configuration_Detail);
                }
            }
            dxOperationMap.put(Label.DXOperation_LoadMetadata, 'lm');
            dxOperationDetailMap.put(Label.DXOperation_LoadMetadata, Label.Load_Metadata_Detail);
        }
    }

    public void availableOperations() {
        operationList = new List<SelectOption>();
        operationList.add(new SelectOption('0', '-- None --'));

        List<Schema.DescribeSObjectResult> dsrList = new List<Schema.DescribeSObjectResult>();
        dsrList.add(Schema.SObjectType.Org__c);
        dsrList.add(Schema.SObjectType.User_Story__c);
        Map<Schema.DescribeSObjectResult, SfdxAPIHelper.ObjectLevelSecurity> olsMap = SfdxAPIHelper.checkOLS(dsrList);

        if (olsMap.get(Schema.SObjectType.Org__c).accessible) {
            operationList.add(new SelectOption('1', Label.DXOperationType_ScratchOrg));
            operationList.add(new SelectOption('2', Label.DXOperationType_DevHub));
        }

        if (olsMap.get(Schema.SObjectType.User_Story__c).accessible) {
            operationList.add(new SelectOption('3', Label.DXOperationType_US));
        }

        operationList.add(new SelectOption('4', Label.DXOperationType_Planning));
    }

    public void orgCredentials() {
        orgCredentials = new List<SelectOption>();
        objectNameMap = new Map<String, String>();
        activeScratchOrgList = new List<Org__c>();
        deletedScratchOrgList = new List<Org__c>();
        String whereClause = '';
        if (selectedOperation == '1' || selectedOperation == '2' || selectedOperation == '0') {
            //whereClause += ' (Scratch_Org_Expiration_Date__c = NULL OR Scratch_Org_Expiration_Date__c > TODAY ) AND Org_Type__c != \'Scratch Org - Test Only\'';
            DateTime dt = System.Now();//initialize datetime with current datetime
            String formatedDt = dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');//format the datetime to make it Dynamic Soql ready
            if (selectedOperation != '0') {
                whereClause += ' (Scratch_Org_Expiration_Date__c = NULL OR Scratch_Org_Expiration_Date__c > ' + formatedDt + ')';
                if (selectedOperation != '2') {
                    whereClause += 'AND Org_Type__c != \'Scratch Org - Test Only\'';
                }
            } else {
                whereClause += ' (Scratch_Org_Expiration_Date__c = NULL OR Scratch_Org_Expiration_Date__c > ' + formatedDt + ')';
            }

            if (selectedOperation == '2' && String.isNotBlank(selectedActionName) && selectedActionName == 'mso') {
                whereClause += ' AND Developer_Hub_Org__c =\'' + String.escapeSingleQuotes(selectedOperationDataId) + '\' AND Scratch_Org_Status__c != null';
            }

            if (selectedOperation == '0' && String.isNotBlank(recordId)) {
                whereClause += ' AND Id =\'' + String.escapeSingleQuotes(recordId) + '\'';
            }
        }

        if (selectedOperation == '4') {
            whereClause += 'Org_Type__c != \'Scratch Org\' AND Org_Type__c != \'Scratch Org - Test Only\'';
        }

        for (Org__c org : SfdxAPIHelper.getOrgCredentials(whereClause)) {
            if ((selectedOperation == '1' && org.Org_Type__c == 'Scratch Org') || (selectedOperation == '0' && (org.Org_Type__c == 'Scratch Org' || org.Org_Type__c == 'Scratch Org - Test Only'))) {
                orgCredentials.add(new SelectOption(org.Id, org.Name));
                objectNameMap.put(org.Id, org.Name);
                if (selectedOperation == '0') {
                    enableScratchOrgOperation = true;
                }
            } else if ((selectedOperation == '2' && org.is_Developer_Hub_Org__c) || (selectedOperation == '0' && org.is_Developer_Hub_Org__c)) {
                orgCredentials.add(new SelectOption(org.Id, org.Name));
                objectNameMap.put(org.Id, org.Name);
                if (selectedOperation == '0') {
                    enableDevHubOperation = true;
                }
            } else if (selectedOperation == '2' && (org.Org_Type__c == 'Scratch Org' || org.Org_Type__c == 'Scratch Org - Test Only') && String.isNotBlank(selectedActionName) && selectedActionName == 'mso') {
                if (org.Scratch_Org_Status__c == 'Active') {
                    activeScratchOrgList.add(org);
                } else if (org.Scratch_Org_Status__c == 'Deleted') {
                    deletedScratchOrgList.add(org);
                }
            } else if (selectedOperation == '4' && String.isNotBlank(selectedActionName) && selectedActionName == 'ma') {
                orgCredentials.add(new SelectOption(org.Id, org.Name));
            }
        }

        orgCredentials = Utilities.selectOptionSortByLabel(orgCredentials);
        if (selectedOperation != '0') {
            if (orgCredentials.size() > 0) orgCredentials.add(0, new SelectOption('-- None --', '-- None --')); else orgCredentials.add(new SelectOption('-- None --', '-- None --'));
        }
    }

    public void retrieveUserStoryCommit() {
        userStoryCommitList = new List<User_Story_Commit__c>();
        if (String.isNotBlank(usId)) {
            userStoryCommitList = [Select Id, Name, Snapshot_Commit__c, View_in_Git__c From User_Story_Commit__c Where User_Story__c = :usId Order By CreatedDate Desc Limit 10];
        }
    }

    public void retrieveSnapshotCommits() {
        snapshotCommitList = new List<Git_Org_Commit__c>();
        if (String.isNotBlank(selectedOperationDataId)) {
            snapshotCommitList = [Select Id, Name, Git_Operation__c, Commit_Date__c, Commit_Message__c, Git_Backup__c, Status__c, View_in_Git__c From Git_Org_Commit__c Where Org__c = :selectedOperationDataId Order By Commit_Date__c Desc Limit 10];
        }
    }

    public void retrieveArtifacts() {
        artifactList = new List<Artifact__c>();
        if (String.isNotBlank(selectedOperationDataId)) {
            artifactList = [Select Id, Name, Description__c, Org_Credential__c, Artifact_Repository__c, RecordTypeId, RecordType.Name From Artifact__c Where Org_Credential__c = :selectedOperationDataId Limit 999];
        }
    }

    public PageReference jobStatusNotification() {
        Boolean jobFinished = ApexPages.currentPage().getParameters().get('jobFinished') == 'true' ? true : false;
        Boolean jobSuccess = ApexPages.currentPage().getParameters().get('jobSuccess') == 'true' ? true : false;
        String jobMessage = ApexPages.currentPage().getParameters().get('jobMessage');
        String jobType = ApexPages.currentPage().getParameters().get('jobType');

        if (jobFinished && jobSuccess && String.isNotBlank(jobType)) {
            if (jobType == CopadoNotificationHelper.DX_CREATE_ORG) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.Scratch_Org_Created_Success));
            } else if (jobType == CopadoNotificationHelper.DX_LOAD_METADATA) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.Load_Metadata_Success));
            } else if (jobType == CopadoNotificationHelper.DX_ORG_IDE_DETAILS) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.Password_Success));
            } else if (jobType == CopadoNotificationHelper.DX_DELETE_ORG) {
                PageReference dxOperationPage = Page.DXOperation;
                dxOperationPage.setRedirect(true);
                return dxOperationPage;
            }
        } else if (jobFinished && !jobSuccess && String.isNotBlank(jobMessage)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, jobMessage));
        }
        return null;
    }

    public void setBranchName() {
        dxBranchName = ApexPages.currentPage().getParameters().get('branchName');
    }

    public void populateDeployments() {
        deploymentList = new List<SelectOption>();
        deploymentList.add(new SelectOption('-- None --', '-- None --'));

        if (String.isNotBlank(sourceOrgId)) {
            for (Deployment__c dep : [Select Id, Name From Deployment__c Where From_Org__c = :sourceOrgId And Promotion__c = null And Status__c = 'Draft']) {
                deploymentList.add(new SelectOption(dep.Id, dep.Name));
            }
        }
    }

    public void initDeploymentStep() {
        if (String.isNotBlank(selectedDeploymentId)) {
            Map<String, String> deploymentFieldsMap = GlobalUtilities.getAllFieldsWithoutSharing('Deployment__c');
            String soqlDeploymentString = 'SELECT ' + deploymentFieldsMap.get(Label.FIELDS) + ' FROM ' + deploymentFieldsMap.get(Label.OBJECT) + ' WHERE Id =\'' + selectedDeploymentId + '\' Limit 1';
            Deployment__c existingDeployment = Database.query(soqlDeploymentString);

            String orgName = '';
            if (String.isNotBlank(selectedOperationDataId)) {
                List<Org__c> orgsList = new List<Org__c>([Select Name From Org__c Where Id = :selectedOperationDataId]);
                orgName = !orgsList.isEmpty() ? orgsList.get(0).Name : '';
            }

            Deployment__c newDeployment = existingDeployment.clone(false, false, false, false);
            newDeployment.Name = orgName + ' - ' + newDeployment.Name;
            Utilities.Secure_DML(newDeployment, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment__c);

            Destination_Org__c destination = new Destination_Org__c();
            destination.Deployment__c = newDeployment.Id;
            destination.To_Org__c = selectedOperationDataId;
            Utilities.Secure_DML(destination, Utilities.DML_Action.INS, schema.Sobjecttype.Destination_Org__c);

            Map<String, String> stepFieldsMap = GlobalUtilities.getAllFieldsWithoutSharing('Step__c');
            String soqlStepString = 'SELECT ' + stepFieldsMap.get(Label.FIELDS) + ' FROM ' + stepFieldsMap.get(Label.OBJECT) + ' WHERE Deployment__c =\'' + existingDeployment.Id + '\'';
            List<Step__c> stepList = Database.query(soqlStepString);

            Map<Id, Step__c> newStepMap = new Map<Id, Step__c>();
            for (Step__c step : stepList) {
                Step__c st = step.clone(false, false, false, false);
                st.Deployment__c = newDeployment.Id;
                newStepMap.put(step.Id, st);
            }

            if (!newStepMap.isEmpty()) {
                Utilities.Secure_DML(newStepMap.values(), Utilities.DML_Action.INS, schema.Sobjecttype.Step__c);

                List<Attachment> attList = [SELECT Id, Body, ContentType, Description, Name, ParentId FROM Attachment WHERE ParentId IN :newStepMap.keySet()];
                List<Attachment> newAttList = new List<Attachment>();
                for (Attachment att : attList) {
                    Attachment newAtt = att.clone(false, false, false, false);
                    newAtt.ParentId = newStepMap.get(att.ParentId).Id;
                    newAttList.add(newAtt);
                }
                if (!newAttList.isEmpty()) {
                    Utilities.Secure_DML(newAttList, Utilities.DML_Action.INS, schema.Sobjecttype.Attachment);
                }
            }

            populateDeployments();
            selectedDeploymentId = newDeployment.Id;

            pageRef = Page.Deployment;
            pageRef.getParameters().put('id', selectedDeploymentId);
            pageRef.getParameters().put('stepsOnly', 'true');
            System.debug('**f**pageRef : ' + pageRef);
        }
    }

    public PageReference executeSteps() {
        PageReference deploymentPageRef = null;
        if (String.isNotBlank(selectedDeploymentId)) {
            deploymentPageRef = Page.DeploymentWizard;
            deploymentPageRef.getParameters().put('id', selectedDeploymentId);
            deploymentPageRef.getParameters().put('gotoStep', 'deploynow');
            deploymentPageRef.getParameters().put('_ui', '2');
            deploymentPageRef.getParameters().put('jobsManagerMatchingKey', '');
            deploymentPageRef.setRedirect(true);
        }
        return deploymentPageRef;
    }
}