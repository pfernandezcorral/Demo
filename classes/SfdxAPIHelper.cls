public with sharing abstract class SfdxAPIHelper {

    public static final string DX_PROJECT_BRANCH = 'project/DX-'; //+scratchOrgId (15 chars)
    public static final string DX_DEFINITION_FILE = 'project-scratch-def.json';
    public static final string DX_PROJECT_FILE = 'sfdx-project.json';
    public static final string DX_DEFAULT_PATH = 'force-app';
    public static final string DX_METADATA_SOURCES = 'metadataSources.json';
    public static final string DX_SCRATCH_ORG_DISPLAY = 'ScratchOrgDisplay.json';
    public static final string DX_CONVERT_IGNORE = 'convertForceIgnore';
    public static final string DX_PUSH_IGNORE = 'pushForceIgnore';

    public static String flowMessage;

    static String SOQL_STRING = 'SELECT {0} FROM {1} WHERE {2}';
    static Set<String> callMethods = new Set<String>{
            'DELETE',
            'GET',
            'HEAD',
            'POST',
            'PUT',
            'TRACE'
    };

    public static String orgDefinitionDefaultKeyFixer(String jsonBody) {
        return jsonBody.replaceAll(',"defaultArtifact":false', '').replace('"defaultArtifact":true', '"default":true');
    }

    public static String prepareOrgDefinition(ScratchOrgDefinition orgTemplate) {
        if (!String.isBlank(orgTemplate.edition)) {
            return JSON.serializePretty(orgTemplate);
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.DX_Edition_is_required));
            return null;
        }
    }

    public static List<Org__c> listDevHubOrgs() {
        return [SELECT Id,Name FROM Org__c WHERE is_Developer_Hub_Org__c = TRUE LIMIT 999];
    }

    public static List<SelectOption> listDevHubOrgOptions() {
        List<SelectOption> devHubs = new List<SelectOption>();
        devHubs.add(new SelectOption('-- None --', '-- None --'));
        for (Org__c dhubs : SfdxAPIHelper.listDevHubOrgs()) {
            devHubs.add(new SelectOption(dhubs.Id, dhubs.Name));
        }
        return devHubs;
    }

    public static HttpResponse callDxJob(String callMethod, String callURL, String callBody, Boolean bodyRequired) {
        if (!callMethods.contains(callMethod)) {
            throw new CopadoDxException(Label.Unknown_HTTP_Request_method);
            return null;
        }
        HttpRequest req = new HttpRequest();
        req.setTimeout(30000);
        DeployAPI.setAuthHeaders(req);
        if (bodyRequired && String.isEmpty(callBody)) {
            return null;
        } else if (!String.isEmpty(callBody)) {
            req.setBody(callBody);
        }
        req.setHeader('Accept', 'application/json');
        req.setHeader('content-type', 'application/json');
        req.setEndpoint(callURL);
        req.setMethod(callMethod);
        Http h = new Http();
        HttpResponse res = h.send(req);
        return res;
    }

    public static List<Org__c> getOrgCredentials(String whereClause) {
        String orgFields = Utilities.getAllFields('Org__c').get(Label.FIELDS);
        String soql = String.format(SOQL_STRING, new String[]{
                orgFields, 'Org__c', whereClause
        });
        System.debug('*** soql: ' + soql);
        return (List<Org__c>) Database.query(soql);
    }

    public static List<Org__c> getOrgCredentials() {
        return SfdxAPIHelper.getOrgCredentials(null);
    }

    public static List<Artifact__c> getArtifacts() {
        String orgFields = Utilities.getAllFields('Artifact__c').get(Label.FIELDS);
        String whereClause = ' Org_Credential__c != NULL AND Artifact_Repository__c != NULL';
        String soql = String.format(SOQL_STRING, new String[]{
                orgFields, 'Artifact__c', whereClause
        });
        System.debug('*** soql: ' + soql);
        return (List<Artifact__c>) Database.query(soql);
    }

    public static List<Artifact__c> getArtifacts(String whereClause) {
        String orgFields = Utilities.getAllFields('Artifact__c').get(Label.FIELDS);
        System.debug('**f**whereClause : ' + whereClause);
        String soql = String.format(SOQL_STRING, new String[]{
                orgFields, 'Artifact__c', whereClause
        });
        System.debug('*** soql: ' + soql);
        return (List<Artifact__c>) Database.query(soql);
    }

    public static String generateSFDXProjectJSON(sfdxProject project) {
        if (!project.packageDirectories.isEmpty()) {
            return JSON.serializePretty(project);
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.DX_Select_at_least_one_artifact));
            return null;
        }
    }

    //Given a Scratch org Id, get the org Id of the artifacts or Org where de metadata was selected
    public static String getSOartifactParentId(String SOId) {
        String oId = '';
        if (String.isNotBlank(SOId)) {
            List<Attachment> mSTatt = [SELECT Body FROM Attachment WHERE ParentId = :SOId AND Name = :DX_METADATA_SOURCES ORDER BY CreatedDate DESC LIMIT 1];
            if (!mSTatt.isEmpty()) {
                Map<String, Object> deserializedJsonMap = (Map<String, Object>) JSON.deserializeUntyped(mSTatt.get(0).Body.toString());
                String mSourceType = deserializedJsonMap.containsKey('metadataSourceType') ? String.ValueOf(deserializedJsonMap.get('metadataSourceType')) : '';
                String mSource = deserializedJsonMap.containsKey('metadataSource') ? String.ValueOf(deserializedJsonMap.get('metadataSource')) : '';
                if (String.isNotBlank(mSource) && String.isNotBlank(mSource) && mSourceType == 'org') {
                    oId = mSource;
                } else if (String.isNotBlank(mSource) && String.isNotBlank(mSourceType) && mSourceType == 'artifact') {
                    String firstArtifactId = mSource.split(',')[0];
                    List<Artifact__c> parentOrg = [SELECT Org_Credential__c FROM Artifact__c WHERE Id = :firstArtifactId];
                    if (!parentOrg.isEmpty() && parentOrg[0].Org_Credential__c != null) {
                        oId = parentOrg[0].Org_Credential__c;
                    }
                }
            }
        }
        return oId;
    }

    public class ScratchOrgDefinition {
        public String orgName { get; set; }
        public String country { get; set; }
        public String username { get; set; }
        public String adminEmail { get; set; }
        public String edition { get; set; }
        public String description { get; set; }
        public Boolean hasSampleData { get; set; }
        public String language { get; set; }
        public List<String> features { get; set; }
        public OrgPreferences orgPreferences { get; set; }

        public scratchOrgDefinition(String orgName, String country, String username, String adminEmail, String edition, String description, Boolean hasSampleData, String language, List<String> features, OrgPreferences orgPreferences) {
            this.orgName = orgName;
            this.country = country;
            this.username = username;
            this.adminEmail = adminEmail;
            this.edition = edition;
            this.description = description;
            this.hasSampleData = hasSampleData;
            this.language = language;
            this.features = features;
            this.orgPreferences = orgPreferences;
        }
    }
    public static Deployment_Flow__c usDeploymentFlow(String usId) {
        try {
            User_Story__c us = [SELECT Id,Project__c,Project__r.Deployment_Flow__c,Release__c,Release__r.Project__r.Deployment_Flow__c FROM User_Story__c WHERE Id = :usId LIMIT 1];
            String dfId;

            if (us.Project__r.Deployment_Flow__c != null) {
                dfId = us.Project__r.Deployment_Flow__c;
            } else if (us.Release__r.Project__r.Deployment_Flow__c != null) {
                dfId = us.Release__r.Project__r.Deployment_Flow__c;
            }

            Deployment_Flow__c depFlow = [
                    SELECT Id, Name,Enable_Copado_DX__c,Copado_DX_Mode__c, (
                            SELECT Id,Name,Enable_as_Scratch_Org_Destination__c,Destination_Environment__c,
                                    Destination_Environment__r.Name,Source_Environment__c,Source_Environment__r.Name
                            FROM Deployment_Flow_Steps__r
                            WHERE Enable_as_Scratch_Org_Destination__c != NULL
                    )
                    FROM Deployment_Flow__c
                    WHERE Id = :dfId
                    LIMIT 1
            ];
            return depFlow;
        } catch (Exception e) {
            flowMessage = Label.UNEXPECTED_DX_DF_ERROR + ' ' + e.getMessage()+' '+e.getStackTraceString();
            return null;
        }
    }
    public static Boolean isDXEnabledForUSDeploymentFlow(Deployment_Flow__c depFlow) {
        if (depFlow == null) {
            flowMessage = Label.DX_NO_US_FLOW;
            return false;
        }
        if (!depFlow.Enable_Copado_DX__c) {
            flowMessage = Label.DX_NOT_ENABLED_DF;
            return false;
        }
        if (depFlow.Deployment_Flow_Steps__r.size() == 0) {
            flowMessage = Label.DF_HAS_NO_DX_TARGET;
            return false;
        }
        return true;
    }
    public static Boolean isDXEnabledForUSDeploymentFlow(String usId) {
        Deployment_Flow__c depFlow = usDeploymentFlow(usId);
        return isDXEnabledForUSDeploymentFlow(depFlow);
    }
    public static String dxModeForUserStory(String usId) {
        Deployment_Flow__c depFlow = usDeploymentFlow(usId);
        return dxModeForUserStory(depFlow);
    }
    public static String dxModeForUserStory(Deployment_Flow__c depFlow) {
        return depFlow.Copado_DX_Mode__c != null ? depFlow.Copado_DX_Mode__c : '';
    }

    public static Map<Schema.DescribeSObjectResult, ObjectLevelSecurity> checkOLS(List<Schema.DescribeSObjectResult> stypeList) {
        Map<Schema.DescribeSObjectResult, ObjectLevelSecurity> objectLevelSecurityMap = new Map<Schema.DescribeSObjectResult, ObjectLevelSecurity>();

        for (Schema.DescribeSObjectResult dsr : stypeList) {
            ObjectLevelSecurity ols = new ObjectLevelSecurity();
            if (dsr.isAccessible()) {
                ols.accessible = true;
            }
            if (dsr.isCreateable()) {
                ols.creatable = true;
            }
            if (dsr.isDeletable()) {
                ols.deleteable = true;
            }
            if (dsr.isUpdateable()) {
                ols.updateable = true;
            }
            if (dsr.isUndeletable()) {
                ols.undeletable = true;
            }
            objectLevelSecurityMap.put(dsr, ols);
        }
        return objectLevelSecurityMap;
    }

    public static ObjectLevelSecurity checkOLS(Schema.DescribeSObjectResult stype) {
        ObjectLevelSecurity ols = new ObjectLevelSecurity();
        if (stype.isAccessible()) {
            ols.accessible = true;
        }
        if (stype.isCreateable()) {
            ols.creatable = true;
        }
        if (stype.isDeletable()) {
            ols.deleteable = true;
        }
        if (stype.isUpdateable()) {
            ols.updateable = true;
        }
        if (stype.isUndeletable()) {
            ols.undeletable = true;
        }
        return ols;
    }

    public class ObjectLevelSecurity {
        public Boolean accessible { get; set; }
        public Boolean creatable { get; set; }
        public Boolean deleteable { get; set; }
        public Boolean updateable { get; set; }
        public Boolean undeletable { get; set; }

        public objectLevelSecurity() {
            this.accessible = false;
            this.creatable = false;
            this.updateable = false;
            this.deleteable = false;
            this.undeletable = false;
        }
    }

    public class OrgPreferences {
        public List<String> enabled { get; set; }
        public List<String> disabled { get; set; }

        public orgPreferences() {
            this.enabled = new List<String>();
            this.disabled = new List<String>();
        }
        public orgPreferences(List<String> enabled, List<String> disabled) {
            this.enabled = enabled;
            this.disabled = disabled;
        }
    }

    public class SourceStatus {
        public String copadoJobId { get; set; }
        public String ok { get; set; }
        public String error { get; set; }
        public String status { get; set; }
    }

    public class Result {
        public String state { get; set; }
        public String fullName { get; set; }
        public String type { get; set; }
        public String filePath { get; set; }
    }

    public class LastBuiltStatus {
        public String copadoJobId { get; set; }
        public String ok { get; set; }
    }

    public class Error {
        public String message { get; set; }
        public integer status { get; set; }
        public String stack { get; set; }
        public String name { get; set; }
        public String action { get; set; }
    }

    public class sfdxProject {
        public List<sfdxProjectArtifacts> packageDirectories { get; set; }
        public String namespace { get; set; }
        public String sfdcLoginUrl { get; set; }
        public String sourceApiVersion { get; set; }

        public sfdxProject(List<sfdxProjectArtifacts> packageDirectories, String namespace, String sfdcLoginUrl, String sourceApiVersion) {
            this.packageDirectories = packageDirectories;
            this.namespace = namespace;
            this.sfdcLoginUrl = sfdcLoginUrl;
            this.sourceApiVersion = sourceApiVersion;
        }
    }

    public class metadataSources {
        public String metadataSource { get; set; }
        public String metadataSourceType { get; set; }
        public List<String> selectedArtifactIDs { get; set; }
        public String repositoryId { get; set; }
        public Boolean isPatch { get; set; }

        public metadataSources() {
            this.metadataSource = '';
            this.metadataSourceType = '';
            this.selectedArtifactIDs = new List<String>();
            this.repositoryId = '';
            this.isPatch = false;
        }
        public metadataSources(String metadataSource, String metadataSourceType, List<String> selectedArtifactIDs, String repositoryId) {
            this.metadataSource = metadataSource;
            this.metadataSourceType = metadataSourceType;
            this.selectedArtifactIDs = selectedArtifactIDs;
            this.repositoryId = repositoryId;
            this.isPatch = false;
        }
        public metadataSources(String metadataSource, String metadataSourceType, String repositoryId) {
            this.metadataSource = metadataSource;
            this.metadataSourceType = metadataSourceType;
            this.selectedArtifactIDs = new List<String>();
            this.repositoryId = repositoryId;
            this.isPatch = false;
        }
    }

    public class sfdxProjectArtifacts {
        public String path { get; set; }
        public Boolean defaultArtifact { get; set; }

        public sfdxProjectArtifacts(String path, Boolean defaultArtifact) {
            this.path = path;
            this.defaultArtifact = defaultArtifact;
        }
    }

    public class sfdxOrgDisplay {
        public String username { get; set; }
        public String id { get; set; }
        public String connectedStatus { get; set; }
        public String accessToken { get; set; }
        public String instanceURL { get; set; }
        public String clientId { get; set; }
        public String password { get; set; }

        public sfdxOrgDisplay(String username, String id, String connectedStatus, String accessToken, string instanceURL, string clientId) {
            this.username = username;
            this.id = id;
            this.connectedStatus = connectedStatus;
            this.accessToken = accessToken;
            this.instanceURL = instanceUrl;
            this.clientId = clientId;
        }
        public sfdxOrgDisplay() {
            this.username = '';
            this.id = '';
            this.connectedStatus = '';
            this.accessToken = '';
            this.instanceURL = '';
            this.clientId = '';
            this.password = '';
        }
    }

    public class CopadoDxException extends Exception {
    }
}