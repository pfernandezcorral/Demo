public with sharing class UserStoryMetadataExt {
    public User_Story_Metadata__c usMetadata {get; set;}
    public List<User_Story_Metadata__c> usMetadatas {get; set;}
    private ApexPages.Standardcontroller controller {get; set;}
    public Map<String, User_Story_Metadata__c> usmMap {get; set;}
    public Map<String,pullConfig> usConfigMap {get;set;}
    public PullConfig latestPull {get;set;} 

    public UserStoryMetadataExt(ApexPages.StandardController stdController) {
        controller = stdController;
        retrieveMetadata();
    }

    public void retrieveMetadata() {
        usmMap = new Map<String, User_Story_Metadata__c>();
        try{
        usMetadata = [SELECT Id, Name, User_Story__r.Name, User_Story__r.Project__r.Deployment_Flow__c, User_Story__r.Release__r.Project__r.Deployment_Flow__c, Status__c, Status_Icon__c, Metadata_API_Name__c, User_Story__c, User_Story__r.Environment__c, User_Story__r.User_Story_Title__c, LastModifiedDate 
        FROM User_Story_Metadata__c WHERE Id = :controller.getId() AND User_Story__r.Stop_Indexing_Metadata__c != true LIMIT 1];
            }catch(Exception e){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, 'This user story has been marked to stop indexing metadata.')); //To do: Change This for a Custom label. Patchable
            }

        if (usMetadata == null) {
            usMetadata = new User_Story_Metadata__c();
        }
        usMetadatas = new List<User_Story_Metadata__c>();
        for (User_Story_Metadata__c usm : [SELECT Name, User_Story__r.Name, User_Story__r.Project__r.Deployment_Flow__c, User_Story__r.Release__r.Project__r.Deployment_Flow__c, Status_Icon__c, Metadata_API_Name__c, Status__c, LastModifiedDate, User_Story__c, User_Story__r.Environment__c, User_Story__r.User_Story_Title__c 
            FROM User_Story_Metadata__c WHERE Id != :usMetadata.Id AND Metadata_API_Name__c = :usMetadata.Metadata_API_Name__c AND User_Story__r.Stop_Indexing_Metadata__c != true]) {
            usMetadatas.add(usm);
            usmMap.put(usm.Id, usm);
        }
    }
    public PageReference preparePullRequest() {
        if(usConfigMap == null){
            usConfigMap = new Map<String,pullConfig>();
        }
        String compareUS = ApexPages.currentPage().getParameters().get('compareUS');
        System.debug(loggingLevel.Error, '*** compareUS: ' + compareUS);
        System.debug(loggingLevel.Error, '*** usmMap.containsKey(compareUS): ' + usmMap.containsKey(compareUS));
        if (String.isBlank(compareUS) || !usmMap.containsKey(compareUS)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, 'Nothing to compare.'));
            return null;
        } else {
            // comment
            if(usConfigMap.containsKey(compareUS)) {
                latestPull = usConfigMap.get(compareUS);
                System.debug(loggingLevel.Error, '*** latestPull: ' + latestPull);
                return null;
            }

            String baseDF, compareDF;
            if (String.isBlank(usMetadata.User_Story__r.Project__c) && String.isBlank(usMetadata.User_Story__r.Release__c)) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, LABEL.BASE_US_PROJECT_OR_RELEASE));
                return null;
            } else if (String.isBlank(usMetadata.User_Story__r.Project__r.Deployment_Flow__c) && String.isBlank(usMetadata.User_Story__r.Release__r.Project__r.Deployment_Flow__c)) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, LABEL.BASE_US_DEPLOYMENT_FLOW));
                return null;
            } else {
                baseDF = !String.isBlank(usMetadata.User_Story__r.Project__r.Deployment_Flow__c) ? usMetadata.User_Story__r.Project__r.Deployment_Flow__c : usMetadata.User_Story__r.Release__r.Project__r.Deployment_Flow__c;
            }
            User_Story_Metadata__c tempUS = usmMap.get(compareUS);
            if (String.isBlank(tempUS.User_Story__r.Project__c) && String.isBlank(tempUS.User_Story__r.Release__c)) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, LABEL.COMPAIRING_US_PROJECT_OR_RELEASE));
                return null;
            } else if (String.isBlank(tempUS.User_Story__r.Project__r.Deployment_Flow__c) && String.isBlank(tempUS.User_Story__r.Release__r.Project__r.Deployment_Flow__c)) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, LABEL.COMPAIRING_US_DEPLOYMENT_FLOW));
                return null;
            } else {
                compareDF = !String.isBlank(tempUS.User_Story__r.Project__r.Deployment_Flow__c) ? tempUS.User_Story__r.Project__r.Deployment_Flow__c : tempUS.User_Story__r.Release__r.Project__r.Deployment_Flow__c;
            }

            if (baseDF != compareDF) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, LABEL.BASE_COMPARING_US_FLOW));
                return null;
            } else {
                List<String> extraFields = new List<String>();
                extraFields.add(Settings.ns+'Git_Repository__r.Pull_Request_Base_URL__c');
                extraFields.add(Settings.ns+'Git_Repository__r.Git_Provider__c');
                GlobalUtilities.deploymentFlowDetails flowDetails = GlobalUtilities.getDeploymentFlowDetails(baseDF, String.join(extraFields,', '));
                if (flowDetails.flow.Active__c) {
                    if (String.isBlank(flowDetails.flow.Git_Repository__r.Pull_Request_Base_URL__c) || String.isBlank(flowDetails.flow.Git_Repository__r.Git_Provider__c) ) {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, LABEL.PULLREQUEST_BASE_URL_AND_TYPE));
                        return null;
                    }else{
                        latestPull = new PullConfig(flowDetails.flow.Git_Repository__r.Git_Provider__c,flowDetails.flow.Git_Repository__r.Pull_Request_Base_URL__c,'feature/'+usMetadata.User_Story__r.Name, 'feature/'+tempUS.User_Story__r.Name);
                        System.debug(loggingLevel.Error, '*** latestPull2: ' + latestPull);
                        usConfigMap.put(compareUS,latestPull);
                        return null;
                    }
                } else {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, LABEL.FLOW_NEEDS_TO_BE_ACTVE));
                    return null;
                }
            }
            return null;
        }
    }
    public class PullConfig{
        public String gitType {get;set;}
        public String pullURL {get;set;}
        public String base {get;set;}
        public String compare {get;set;}

        public pullConfig(String gitType, String pullURL, String base, String compare){
            this.gitType = gitType;
            this.pullURL = pullURL;
            this.base = base;
            this.compare = compare;
        }
    }
    public List<SelectOption> getStatuses() {
        List<SelectOption> options = new List<SelectOption>();

        Schema.DescribeFieldResult statusDescribe = User_Story_Metadata__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> statuses = statusDescribe.getPicklistValues();

        for ( Schema.PicklistEntry f : statuses) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }

    private String Status = '';
    public String metadataId = '';

    public void updateStatuses() {
        metadataId = usMetadata.Id;
        updateStatus();
        for (User_Story_Metadata__c usm : usMetadatas) {
            metadataId = usm.Id;
            updateStatus();
        }
        // Saved for Copado v9.0 retrieveMetadata();
    }
    public PageReference updateStatus() {
        Status = Apexpages.currentPage().getParameters().get('Status');
        Boolean isSingleUpdate = false;
        if (metadataId == '') {
            metadataId = Apexpages.currentPage().getParameters().get('metadataId');
            isSingleUpdate = true;
        }

        if (usmMap.get(metadataId) != null) {
            usmMap.get(metadataId).Status__c = Status;
            update usmMap.get(metadataId);
        } else if (String.valueOf(usMetadata.Id) == metadataId) {
            usMetadata.Status__c = Status;
            update usMetadata;
        }

        // Saved for Copado v9.0 if(isSingleUpdate)retrieveMetadata();
        metadataId = '';

        return null;
    }
    /**
     * Overrides standard delete function
     * @return Pagereference
     * @see Utilities
     */
    public PageReference deleteJob() {
        if (usMetadata.id != null) {

            PageReference retPage;
            if (usMetadata.User_Story__c != null) {
                retPage = new PageReference('/' + usMetadata.User_Story__c);
            } else {
                retPage = new PageReference('/home/home.jsp');
            }
            retPage.setRedirect(true);
            try {
                Utilities.Secure_DML(usMetadata, Utilities.DML_Action.DEL, schema.Sobjecttype.User_Story_Metadata__c);
                return retPage;
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.ERROR + ' : ' + e.getMessage()));
                return null;
            }

        }
        return null;
    }


}