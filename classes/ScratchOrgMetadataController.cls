/**
 * Created by mertyalti on 12/01/2018.
 */

public with sharing class ScratchOrgMetadataController extends ScratchOrgWizardComponentBase {
    public Boolean showArtifacts { get; set; }
    public Boolean showArtifactsUMP { get; set; }
    public Boolean showBranches { get; set; }
    public Boolean showPatchOptions { get; set; }
    public Boolean showOrgs { get; set; }
    public Boolean temp { get; set; }
    public String convertSource { get; set; }
    public String typeName { get; set; }
    private Map<String, String> artifactIdToName { get; set; }
    private Map<String, String> artifactNameToId { get; set; }
    public SfdxAPIHelper.sfdxProject artifactProject { get; set; }
    public SfdxAPIHelper.metadataSources metadataSources { get; set; }
    public String templateId { get; set; }
    public String templateName { get; set; }
    public String repoName { get; set; }
    public String repoId { get; set; }
    public String releaseId { get; set; }
    public String releaseName { get; set; }
    public String orgId { get; set; }
    public String orgName { get; set; }

    private String projectJson;
    private String mdSourcesJson;

    public String attachmentBodyConvert { get; set; }
    public String attachmentBodyPush { get; set; }

    public String branchGridMode { get; set; }
    private String sourceOrgCredential;
    private Boolean sourceIsEmpty;

    public SfdxAPIHelper.ObjectLevelSecurity artifactSecurity { get; set; }
    public SfdxAPIHelper.ObjectLevelSecurity gitSecurity { get; set; }
    public SfdxAPIHelper.ObjectLevelSecurity orgSecurity { get; set; }
    public SfdxAPIHelper.ObjectLevelSecurity templateSecurity { get; set; }

    public List<SelectOption> selectedArtifacts { get; set; }
    public List<SelectOption> artifatsOptionList { get; set; }
    public String defaultArtifact { get; set; }
    public ScratchOrgMetadataController() {
        artifactSecurity = SfdxAPIHelper.checkOLS(Schema.sObjectType.Artifact__c);
        gitSecurity = SfdxAPIHelper.checkOLS(Schema.sObjectType.Git_Repository__c);
        orgSecurity = SfdxAPIHelper.checkOLS(Schema.sObjectType.Org__c);
        templateSecurity = SfdxAPIHelper.checkOLS(Schema.sObjectType.Scratch_Org_Project_Template__c);
        resetDom();
        selectedArtifacts.add(new SelectOption(SfdxAPIHelper.DX_DEFAULT_PATH, SfdxAPIHelper.DX_DEFAULT_PATH));
    }
    public PageReference loadMetadata() {
        generateSfdxProjectJson();
        if(sourceIsEmpty){
            return null;
        }
        if (typeName == 'artifact' || typeName == 'artifactUMP') {
            if(String.isNotBlank(sourceSelections)){
                SfdxAPI.loadMetadataFromArtifacts(getProjectJson(), getMdSourcesJson(), selectedOrgIdFromDxOperation, dxDeploymentFlowGitRepo, 'true');
            }
        } else if (typeName == 'patch') {
            Boolean isConvertSource = String.isNotBlank(convertSource) ? convertSource == 'true' ? true : false : false;
            SfdxAPI.loadMetadataFromGit(getProjectJson(), getMdSourcesJson(), selectedOrgIdFromDxOperation, repoId, dxBranchName, '', 'true', isConvertSource);
        } else if (typeName == 'branch') {
            Boolean isConvertSource = String.isNotBlank(convertSource) ? convertSource == 'true' ? true : false : false;
            if(String.isNotBlank(dxBranchName) && dxBranchName.startsWith(SfdxAPIHelper.DX_PROJECT_BRANCH) && String.isNotBlank(convertSource) && convertSource == 'true'){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Branch_Format_Is_Not_Matched + ' ' + dxBranchName));
                return null;
            }
            SfdxAPI.loadMetadataFromGit(getProjectJson(), getMdSourcesJson(), selectedOrgIdFromDxOperation, repoId, dxBranchName, '', 'true', isConvertSource);
        } else if (typeName == 'org') {
            SfdxAPI.convertIgnore = attachmentBodyConvert;
            SfdxAPI.pushIgnore = attachmentBodyPush;
            SfdxAPI.loadMetadataFromOrg(getProjectJson(), getMdSourcesJson(), selectedOrgIdFromDxOperation, sourceSelections, '');
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.Unsupported_Metadata_Source));
        }

        PageReference pr = Page.DXOperation;
        if (String.isNotBlank(devHubOrgId)) {
            pr.getParameters().put('id', devHubOrgId);
        }
        pr.setRedirect(true);
        return pr;
    }
    public void resetDom() {
        showArtifacts = false;
        showArtifactsUMP = false;
        showBranches = false;
        showOrgs = false;
        showTemplateButtons = true;
        artifatsOptionList = new List<SelectOption>();
        selectedArtifacts = new List<SelectOption>();
        templateId = null;
        templateName = '';

        repoId = '000000000000000';
        orgId = '000000000000000';
        artifactProject = new SfdxAPIHelper.sfdxProject(new List<SfdxAPIHelper.sfdxProjectArtifacts>(), '', 'https://login.salesforce.com', '41.0');
        defaultArtifact = '';
        metadataSources = new SfdxAPIHelper.metadataSources();
    }
    public String getProjectJson(){
        system.debug(projectJson);
        return projectJson;
    }
    public String getMdSourcesJson(){
        system.debug(mdSourcesJson);
        return mdSourcesJson;
    }

    //Backend will create attachments
    public void generateSfdxProjectJson() {
        sourceIsEmpty = false;
        SfdxAPIHelper.sfdxProject project = artifactProject;

        SfdxAPIHelper.sfdxProjectArtifacts directory;
        SfdxAPIHelper.metadataSources mdSelections;
        System.debug('**f**typeName : ' + typeName);
        if (typeName == null) return ;
        if (typeName == 'artifact' || typeName == 'artifactUMP') {
            if (String.isBlank(sourceSelections) && typeName == 'artifact') {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.Artifact_Selection_Validation));
                sourceIsEmpty = true;
                return;
            }else if(String.isBlank(sourceSelections) && typeName == 'artifactUMP'){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.Select_Package_To_Load));
                sourceIsEmpty = true;
                return;
            }
            System.debug('**f**sourceSelections : ' + sourceSelections);
            mdSelections = new SfdxAPIHelper.metadataSources(sourceSelections.replace('[', '').replace(']', '').replaceAll('\\s+', ''), typeName,'');
            List<SfdxAPIHelper.sfdxProjectArtifacts> artifactDirectories = new List<SfdxAPIHelper.sfdxProjectArtifacts>();
            for (String art : sourceSelections.replace('[', '').replace(']', '').split(',')) {
                if(!art.isWhitespace()) {
                    mdSelections.selectedArtifactIDs.add(art.replaceAll('\\s+', ''));
                }
            }
            artifactDirectories.add(new SfdxAPIHelper.sfdxProjectArtifacts(SfdxAPIHelper.DX_DEFAULT_PATH, true));
            for (Artifact__c artifacts : [Select Name From Artifact__c Where Id In :mdSelections.selectedArtifactIDs]) {
                artifactDirectories.add(new SfdxAPIHelper.sfdxProjectArtifacts(artifacts.Name, false));
            }

            project.packageDirectories = artifactDirectories;
        } else if (typeName == 'branch' || typeName == 'org') {
            directory = new SfdxAPIHelper.sfdxProjectArtifacts(sourceSelections != null ? sourceSelections : SfdxAPIHelper.DX_DEFAULT_PATH, true);
            project.packageDirectories = new List<SfdxAPIHelper.sfdxProjectArtifacts>{
                    directory
            };
            if(String.isNotBlank(dxBranchName) && String.isBlank(sourceSelections)){
                sourceSelections = dxBranchName;
            }
            if (String.isBlank(sourceSelections) && typeName == 'branch') {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.Select_a_Branch));
                sourceIsEmpty = true;
                return;
            }
            else if((String.isBlank(sourceSelections) || sourceSelections == '-- None --' )&& typeName == 'org'){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.Select_Org_Credential_To_Load));
                sourceIsEmpty = true;
                return;
            }
            String callType = showPatchOptions &&  typeName == 'branch' ? 'tag' : typeName;
            mdSelections = new SfdxAPIHelper.metadataSources(sourceSelections, callType, repoId);
            if(callType == 'tag'){
                mdSelections.isPatch = true;
            }
        } else if(typeName == 'patch'){
            directory = new SfdxAPIHelper.sfdxProjectArtifacts(sourceSelections != null ? sourceSelections : SfdxAPIHelper.DX_DEFAULT_PATH, true);
            project.packageDirectories = new List<SfdxAPIHelper.sfdxProjectArtifacts>{
                    directory
            };
            if(String.isNotBlank(dxBranchName) && String.isBlank(sourceSelections)){
                sourceSelections = dxBranchName;
            }
            if (String.isBlank(sourceSelections) && typeName == 'patch') {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.Select_Patch_To_Load));
                sourceIsEmpty = true;
                return;
            }
            System.debug(LoggingLevel.INFO,'***sourceSelections :'+sourceSelections);
            mdSelections = new SfdxAPIHelper.metadataSources(sourceSelections, 'tag', repoId);
            mdSelections.isPatch = true;
        }else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.Unsupported_Metadata_Source));
            return;
        }

        projectJson = JSON.serialize(project);
        mdSourcesJson = JSON.serializePretty(mdSelections);
    }

    public List<SelectOption> getSfdxFormat(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('true','Metadata API'));
        options.add(new SelectOption('false','DX Format'));
        return options;
    }
    public List<SelectOption> getOrgCredentialsWithArtifatcsList() {
        List<SelectOption> orgCredentials = new List<SelectOption>();
        Set<String> orgCredentialIdSet = new Set<String>();

        String recordTyeId = typeName == 'artifact' ? Schema.SObjectType.Artifact__c.getRecordTypeInfosByName().get('Git Artifact').getRecordTypeId() : typeName == 'artifactUMP' ? Schema.SObjectType.Artifact__c.getRecordTypeInfosByName().get('Package Artifact').getRecordTypeId() : '';
        String whereClauseArtifact = typeName == 'artifact' ? ' Org_Credential__c != null AND Artifact_Repository__c != NULL' : typeName == 'artifactUMP' ? ' Org_Credential__c != null AND Artifact_Repository__c = NULL' : '';

        if(String.isNotBlank(recordTyeId)){
            whereClauseArtifact += ' AND RecordTypeId =\'' + String.escapeSingleQuotes(recordTyeId) + '\'';
        }
        for (Artifact__c art : SfdxAPIHelper.getArtifacts(whereClauseArtifact)) {
            orgCredentialIdSet.add(art.Org_Credential__c);
        }
        String whereClause = ' (Scratch_Org_Expiration_Date__c = NULL OR Scratch_Org_Expiration_Date__c > TODAY ) AND Org_Type__c != \'Scratch Org - Test Only\'';
        for (Org__c o : SfdxAPIHelper.getOrgCredentials(whereClause)) {
            if(orgCredentialIdSet.contains(o.Id)){
                orgCredentials.add(new SelectOption(o.Id, o.Name));
            }
        }
        orgCredentials = Utilities.selectOptionSortByLabel(orgCredentials);
        if(orgCredentials.size() > 0) orgCredentials.add(0,new SelectOption('-- None --', '-- None --'));
        else orgCredentials.add(new SelectOption('-- None --', '-- None --'));
        return orgCredentials;
    }
    public void getArtifacts() {
        artifactIdToName = new Map<String, String>();
        artifactNameToId = new Map<String, String>();
        artifatsOptionList = new List<SelectOption>();
        String whereClause = '';

        String recordTyeId = typeName == 'artifact' ? Schema.SObjectType.Artifact__c.getRecordTypeInfosByName().get('Git Artifact').getRecordTypeId() : typeName == 'artifactUMP' ? Schema.SObjectType.Artifact__c.getRecordTypeInfosByName().get('Package Artifact').getRecordTypeId() : '';

        if(typeName == 'artifact'){
            whereClause = String.isNotBlank(selectedOrgId) && selectedOrgId != '-- None --' ? ' Org_Credential__c =\'' + String.escapeSingleQuotes(selectedOrgId) + '\' AND Artifact_Repository__c != NULL' : ' Artifact_Repository__c != NULL';
        } else if(typeName == 'artifactUMP'){
            whereClause = String.isNotBlank(selectedOrgId) && selectedOrgId != '-- None --' ? ' Org_Credential__c =\'' + String.escapeSingleQuotes(selectedOrgId) + '\' AND Artifact_Repository__c = NULL' : ' Artifact_Repository__c = NULL';
        }

        if(String.isNotBlank(recordTyeId)){
            whereClause += ' AND RecordTypeId =\'' + String.escapeSingleQuotes(recordTyeId) + '\'';
        }
        if(String.isNotBlank(selectedOrgId) && selectedOrgId != '-- None --'){
            for (Artifact__c o : SfdxAPIHelper.getArtifacts(whereClause)) {
                artifatsOptionList.add(new SelectOption(o.Id, o.Name));
                artifactIdToName.put(o.Id, o.Name);
                artifactNameToId.put(o.Name, o.Id);
            }

            List<String> artifactsIdList = new List<String>();
            if (String.isNotBlank(String.valueOf(metadataSource))) {
                artifactsIdList = String.valueOf(metadataSource).split(',');
            }
            if (!artifactsIdList.isEmpty()) {
                metadataSources = new SfdxAPIHelper.metadataSources(String.valueOf(metadataSource), typeName, artifactsIdList, repoId);
            }
        }
    }
    public List<SelectOption> getOrgCredentialsList() {
        List<SelectOption> orgCredentials = new List<SelectOption>();
        orgCredentials.add(new SelectOption('-- None --', '-- None --'));
        String whereClause = ' (Scratch_Org_Expiration_Date__c = NULL OR Scratch_Org_Expiration_Date__c > TODAY ) AND Org_Type__c != \'Scratch Org - Test Only\'';
        for (Org__c o : SfdxAPIHelper.getOrgCredentials(whereClause)) {
            orgCredentials.add(new SelectOption(o.Id, o.Name));
        }
        return orgCredentials;
    }
    public void populateOrgId() {
        selectedOrgId = String.isNotBlank(sourceOrgCredential) ? sourceOrgCredential : '-- None --';
    }
    public PageReference readProjectTemplate() {
        templateId = ApexPages.currentPage().getParameters().get('templateId');
        System.debug(loggingLevel.INFO, '*** templateId: ' + templateId);
        try {
            Scratch_Org_Project_Template__c template = [SELECT Id,Name,Project_JSON__c,Developer_Hub_Org__c,Source_Org_Credential__c FROM Scratch_Org_Project_Template__c WHERE Id = :templateId LIMIT 1];
            System.debug(loggingLevel.INFO, '*** template: ' + template);
            templateName = template.Name;
            System.debug('**f**template.Source_Org_Credential__c : ' + template.Source_Org_Credential__c);
            sourceOrgCredential = template.Source_Org_Credential__c;

            populateOrgId();
            getOrgCredentialsWithArtifatcsList();
            getArtifacts();

            artifactProject = (SfdxAPIHelper.sfdxProject) JSON.deserialize(template.Project_JSON__c, SfdxAPIHelper.sfdxProject.class);
            sourceSelections = '';
            List<String> artIds = new List<String>();

            for (SfdxAPIHelper.sfdxProjectArtifacts art : artifactProject.packageDirectories) {
                artIds.add(artifactNameToId.get(art.path));
                /*if (art.defaultArtifact) {
                    defaultArtifact = artifactNameToId.get(art.path);
                }*/
            }
            String artIdsJoined = String.join(artIds, ',');
            metadataSources = new SfdxAPIHelper.metadataSources(artIdsJoined, typeName, artIds, repoId);
            System.debug(LoggingLevel.INFO, '***readProjectTemplate:::metadataSources :' + metadataSources);
            sourceSelections = '[' + artIdsJoined + ']';

            processSelectedArtifact();
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Read_DX_Project_Template_Error + ' ' + ex.getMessage()));
        }
        return null;
    }
    public PageReference processSelectedArtifact() {
        sourceSelections = '[' + String.join(metadataSources.selectedArtifactIDs, ',') + ']';
        return null;
    }
    public PageReference newTemplate() {
        saveProjectTemplate(true);
        return null;
    }
    public PageReference updateTemplate() {
        saveProjectTemplate(false);
        return null;
    }
    private void saveProjectTemplate(Boolean isNew) {
        System.debug('**f**isNew : ' + isNew);
        if (String.isEmpty(templateName)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.SOD_Template_Name_Validation));
            return;
        }
        generateSfdxProjectJson();
        System.debug('**f**artifactProject : ' + artifactProject);
        String projectJSON = sfdxAPIHelper.generateSFDXProjectJSON(artifactProject);
        Scratch_Org_Project_Template__c projectTemplate = new Scratch_Org_Project_Template__c();
        projectTemplate.Name = templateName;
        projectTemplate.Project_JSON__c = projectJSON;
        projectTemplate.Namespace__c = artifactProject.namespace;
        projectTemplate.Api_Version__c = artifactProject.sourceApiVersion;
        projectTemplate.SFDC_Login_Url__c = artifactProject.sfdcLoginUrl;
        System.debug('**f**selectedOrgId : ' + selectedOrgId);
        if (String.isNotBlank(selectedOrgId) && selectedOrgId != '-- None --' && projectTemplate.Source_Org_Credential__c != selectedOrgId) {
            projectTemplate.Source_Org_Credential__c = selectedOrgId;
        }
        System.debug('**f**projectTemplate.Source_Org_Credential__c : ' + projectTemplate.Source_Org_Credential__c);

        if (templateId != null && !isNew) {
            projectTemplate.id = templateId;
        }
        Utilities.Secure_DML(projectTemplate, Utilities.DML_Action.UPS, Schema.sObjectType.Scratch_Org_Project_Template__c);
        templateId = projectTemplate.id;
        if (isNew) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.DX_Template_Success));
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.DX_Template_Success_Update));
        }
    }
    private void setDisableNextButton(Boolean value) {
        if (pageController != null && pageController instanceof CreateUserStoryScratchOrgController) {
            ((CreateUserStoryScratchOrgController) pageController).disableNextButton = value;
        }
    }

    public void refreshBranchCache() {
        if (String.isNotBlank(repoId)) SfdxAPI.retrieveBranchesFromRepository(repoId);
    }
    public void refreshPackagesCache() {
        System.debug(LoggingLevel.INFO, '***repoId :' + orgId);
        if (String.isNotBlank(orgId) && orgId != '000000000000000') SfdxAPI.getListOfPackages(orgId);
    }

    public void cleanRepoSetup() {
        repoId = '';
        repoName = ''; // cleaning previous repo setup since metadata source can be changed.
    }

    public List<SelectOption> getVersions() {
        return VersionPicklistValues.prepareSFVersionPicklist();
    }

    public void setRepo() {
        cleanRepoSetup();
        try {
            Release__c selectedRelease = [SELECT Id,Name,Version__c,Base_Branch__c,Project__c,Project__r.Deployment_Flow__c,Project__r.Deployment_Flow__r.Git_Repository__c FROM Release__c WHERE Id = :releaseId LIMIT 1];
            if (String.isBlank(selectedRelease.Version__c)) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.Release_Does_Not_Have_Version));
            }
            if (String.isBlank(selectedRelease.Base_Branch__c)) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.Selected_Release_Does_Not_Have_Branch));
            }
            if (selectedRelease.Project__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.Selected_Release_Does_Not_Have_Project));
            } else if (selectedRelease.Project__c != null && selectedRelease.Project__r.Deployment_Flow__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.Release_Project_Does_Not_Have_DF));
            } else if (selectedRelease.Project__c != null && selectedRelease.Project__r.Deployment_Flow__c != null && selectedRelease.Project__r.Deployment_Flow__r.Git_Repository__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.Release_Has_No_Git_Related));
            } else {
                repoId = selectedRelease.Project__r.Deployment_Flow__r.Git_Repository__c;
            }
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Release_Selection_Error + ex.getMessage()));
        }
    }

    public PageReference selectType() {
        typeName = ApexPages.currentPage().getParameters().get('typeName');
        selectedOrgId = '-- None --';
        if (typeName == null) return null;
        sourceSelections = null;
        if (typeName == 'artifact') {
            showArtifacts = true;
            showArtifactsUMP = false;
            showBranches = false;
            showOrgs = false;
            //selectedArtifacts = new List<SelectOption>();
            //selectedArtifacts.add(new SelectOption('-- None --', '-- None --'));
            setDisableNextButton(false);
            templateId = null;
            templateName = '';
            artifactProject = new SfdxAPIHelper.sfdxProject(new List<SfdxAPIHelper.sfdxProjectArtifacts>(), '', 'https://login.salesforce.com', '41.0');
            metadataSources = new SfdxAPIHelper.metadataSources();
            artifatsOptionList = new List<SelectOption>();
        } else if (typeName == 'artifactUMP') {
            showArtifacts = false;
            showArtifactsUMP = true;
            showBranches = false;
            showOrgs = false;
            setDisableNextButton(false);
            templateId = null;
            templateName = '';
            artifactProject = new SfdxAPIHelper.sfdxProject(new List<SfdxAPIHelper.sfdxProjectArtifacts>(), '', 'https://login.salesforce.com', '41.0');
            metadataSources = new SfdxAPIHelper.metadataSources();
            artifatsOptionList = new List<SelectOption>();
            System.debug('**f**metadataSources : ' + metadataSources);
        } else if (typeName == 'branch' || typeName == 'patch') {
            if(typeName == 'branch'){
                releaseId = '000000000000000';
                releaseName = '';
                repoId = '000000000000000';
            } else if(typeName == 'patch'){
                repoId = '000000000000000';
                repoName = '';
            }
            System.debug('**f**pageController : ' + pageController);
            if (pageController != null && pageController instanceof CreateUserStoryScratchOrgController) {
                branchGridMode = 'userStoryWizard';
            } else if (pageController != null && pageController instanceof DXOperationController) {
                branchGridMode = 'dxOperations';
            }
            showArtifacts = false;
            showArtifactsUMP = false;
            showBranches = true;
            if (typeName == 'patch') {
                showPatchOptions = true;
            } else {
                showPatchOptions = false;
            }
            showOrgs = false;
            setDisableNextButton(true);
        } else if (typeName == 'org') {
            showArtifacts = false;
            showArtifactsUMP = false;
            showBranches = false;
            showOrgs = true;
            showPatchOptions = false;
            setDisableNextButton(false);
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.Unsupported_Metadata_Source));
        }
        return null;
    }
}