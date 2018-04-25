public with sharing class UserStoryExt {
    public User_Story__c userStory {get; set;}
    public List<flowStepWrapper> visualFlowSteps {get; set;}
    public Boolean hasActiveDeploymentFlow {get; set;}
    public String targetBranch {get; set;}
    public Integer commitCount {get; set;}
    public GlobalUtilities.deploymentFlowDetails flowDetails {get; set;}
    public String userStoriesAheadBehindTitle {get; set;}
    public transient List<User_Story__c> userStoriesAhead {get; set;}
    public transient List<User_Story__c> userStoriesBehind {get; set;}
    public Deployment_Flow_Step__c flowStep {get; set;}
    public boolean scaAccess {get; set;}
    public Boolean showError {get; set;} //**+
    public Boolean showOptions {get; set;}
    public Boolean isUserStoryAhead {get; set;}
    public Boolean enablePoller {get; set;}
    public Boolean showHideMsg {get; set;}

    public UserStoryExt(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) { stdController.addFields(new List<String>(Schema.SObjectType.User_Story__c.fields.getMap().keySet())); }
        if (!Test.isRunningTest()) { stdController.addFields(new List<String>{Settings.ns + 'Project__r.Name',Settings.ns + 'Org_Credential__r.Name',Settings.ns + 'Environment__r.Name',Settings.ns + 'Release__r.Name','Sprint__r.Name',Settings.ns + 'Org_Credential__r.'+Settings.ns +'Org_Type__c'}); }

        showOptions = true;
        showError = false;
        enablePoller = false;
        showHideMsg = false;
        scaAccess = FeatureAccessHelper.isSCAFeatureAccessible() && LicenseHelper.actionIsLicenseEnabled('requestStaticCodeAnalysis');
        hasActiveDeploymentFlow = false;
        this.targetBranch = null;
        this.userStory = GlobalUtilities.getUserStoryById(stdController.getId());
        if (userStory.Last_Validation_Deployment__c != null && !String.isBlank(userStory.Last_Validation_Deployment_Status__c) && !userStory.Last_Validation_Deployment_Status__c.contains('Completed') && !userStory.Last_Validation_Deployment_Status__c.contains('Outdated')) {
            enablePoller = true;
            showHideMsg = true;
        }
        
        if (this.userStory == null) {
            this.userStory = new User_Story__c();
        }
        userStoriesBehind = new List<User_Story__c>();
        userStoriesAhead = new List<User_Story__c>();
        getDeploymentFlowSteps();
        isLicenseAndFeatureEnabled();
        checkForBackPromotedMetadata(this.userStory.Id);
        checkForLastCommitNoChanges(this.userStory.Id);
    }
    public class flowStepWrapper {
        public String style {get; set;}
        public String environment {get; set;}
        public flowStepWrapper(String s, String e) {
            this.style = s;
            this.environment = e;
        }
    }

    public void isLicenseAndFeatureEnabled() {
        if (!LicenseHelper.actionIsLicenseEnabled('viewUserStoryPage')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CAD_License_Restriction));
            showError = true;
            showOptions = false;
        }
        if (!FeatureHelper.isChangeChangeManagementEnabled()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Change_Management_Feature_Not_Enabled));
            showError = true;
            showOptions = false;
        }
        return;
    }
    public Boolean getIsPollerEnabled() { return enablePoller; }
    public void waitForDeployment() {
        Deployment__c deployment;
        try {
            if (Schema.SObjectType.Promotion__c.isQueryable()) {
                deployment = [SELECT Id, Status__c FROM Deployment__c WHERE Promotion__c = : userStory.Last_Validation_Promotion__c LIMIT 1];
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.NOACCESSPROMOTION));
            }
        } catch (Exception e) {
            // No deployment created yet
        }
        if (deployment != null && !deployment.Status__c.contains('Completed')) {
            userStory.Last_Validation_Deployment__c = deployment.Id;
            showHideMsg = true;
            Utilities.Secure_DML(userStory, Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story__c);
        } else if (deployment != null && deployment.Status__c.contains('Completed')) {
            enablePoller = false;
            showHideMsg = false;
        }

    }
    //Id variable to make sure the promotion is created
    private String lastValPromotionId = '';
    public void validateUserStory() {
        enablePoller = true;
        System.debug('### Creating promotion');
        Promotion__c promotion = new Promotion__c(Project__c = userStory.Project__c);
        promotion.Release__c = userStory.Release__c;
        promotion.Source_Org_Credential__c = userStory.Org_Credential__c;
        promotion.Source_Environment__c = userStory.Environment__c;
        promotion.Send_Deployment_Complete_email__c = true;
        promotion.Status__c = 'Validation';
        try {
            Utilities.Secure_DML(promotion, Utilities.DML_Action.INS, schema.Sobjecttype.Promotion__c);
            System.debug('### Creating User Story Promotion');
            Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = userStory.Id, Promotion__c = promotion.Id);
            pus.Name = 'Promoted User Story: ' + userStory.Name;
            Utilities.Secure_DML(pus, Utilities.DML_Action.INS, schema.Sobjecttype.Promoted_User_Story__c);
            lastValPromotionId = promotion.Id;
            system.debug(lastValPromotionId);
            userStory.Last_Validation_Promotion__c = promotion.Id;
            userStory.Last_Validation_Deployment__c = null;
            Utilities.Secure_DML(userStory, Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story__c);
        } catch (Exception e) {
            system.debug('### validate error ' + e.getMessage()); //#ToRemove
            enablePoller = false;

            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
        }
    }
    public PageReference deployValidatedUserStory() {
        if(lastValPromotionId != null && lastValPromotionId != ''){
            system.debug(lastValPromotionId);
            DeployAPI.deployPromotion(lastValPromotionId, userStory.Name, true, userStory.Promote_as_Single_Step__c, userStory.Promotion_Test_Level__c);
            lastValPromotionId = '';
        }
        return null;
    }

    public void getDeploymentFlowSteps() {

        visualFlowSteps = new List<flowStepWrapper>();
        Map<Id, String> envNames = new Map<Id, String>(); // Env.Id, Env.Name
        Map<Id, String> envBranches = new Map<Id, String>(); // Env.Id, Branch Name
        Map<Id, Id> envIds = new Map<Id, Id>(); // SourceEnv.Id, DestinationEnv.Id
        Id flowId;
        try {
            if (userStory.Environment__c != null && (userStory.Project__c != null || userStory.Release__c != null)) {
                User_Story__c us;
                if (Schema.SObjectType.User_Story__c.isQueryable()) {
                    commitCount = [SELECT count() FROM User_Story_Commit__c WHERE User_Story__c = :userStory.Id AND Snapshot_Commit__r.Status__c = 'Complete'];
                    us = [SELECT Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c, Release__r.Base_Branch__c, Base_Branch__c  FROM User_Story__c WHERE Id = :userStory.Id];
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.NOACCESSUSERSTORY));
                }
                if (us.Project__r.Deployment_Flow__c != null) {
                    flowId = us.Project__r.Deployment_Flow__c;
                } else if (us.Release__r.Project__r.Deployment_Flow__c != null) {
                    flowId = us.Release__r.Project__r.Deployment_Flow__c;
                }

                if(us.Release__r.Base_Branch__c != null && us.Base_Branch__c != null && us.Release__r.Base_Branch__c != us.Base_Branch__c) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.USER_STORY_BASE_BRANCH_CONFLICT));
                }

                if (flowId != null) {
                    List<String> extraFields = new List<String>();
                    extraFields.add(Settings.ns + 'Git_Repository__r.Pull_Request_Base_URL__c');
                    extraFields.add(Settings.ns + 'Git_Repository__r.Git_Provider__c');
                    flowDetails = GlobalUtilities.getDeploymentFlowDetails(flowId, String.join(extraFields, ', '));
            
                    if (flowDetails.flow.Active__c) {   
                        hasActiveDeploymentFlow = true;                     
                        for (Deployment_Flow_Step__c step : [SELECT Deployment_Flow__c, Source_Environment__c, Source_Environment__r.Name, Branch__c, Destination_Environment__c, Destination_Environment__r.Name, Last_Merge_Base__c, Last_Merge_CBM_Sync__c, Last_Pull_CBM_Sync__c, Destination_Branch__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :flowDetails.flow.Id]) {
                            if (step.Source_Environment__c != null) {
                                envNames.put(step.Source_Environment__c, step.Source_Environment__r.Name);
                                envBranches.put(step.Source_Environment__c, step.Branch__c);
                                envIds.put(step.Source_Environment__c, step.Destination_Environment__c);
                                if (step.Source_Environment__c == userStory.Environment__c) {
                                    flowStep = step;
                                }
                            }
                            if (step.Destination_Environment__c != null) {
                                envNames.put(step.Destination_Environment__c, step.Destination_Environment__r.Name);
                            }
                        }

                        // Determine the path of environments prior to the current environment
                        Map<Id, Promoted_User_Story__c> promotedUserStories = new Map<Id, Promoted_User_Story__c>(); // <Destination Environment Id, Promoted_User_Story__c>
                        for(Promoted_USer_Story__c pus : [SELECT Id, Promotion__r.Source_Environment__c, Promotion__r.Source_Environment__r.Name, Promotion__r.Destination_Environment__c 
                                                                            FROM Promoted_User_Story__c 
                                                                            WHERE User_Story__c = :userStory.Id AND Promotion__r.Back_Promotion__c != true AND Promotion__r.Source_Environment__c != null AND Promotion__r.Destination_Environment__c != null
                                                                            ORDER BY CreatedDate]) {
                            if(!promotedUserStories.containsKey(pus.Promotion__r.Destination_Environment__c)) {
                                promotedUserStories.put(pus.Promotion__r.Destination_Environment__c, pus);
                            }
                        }
                        System.debug('pus.Size: '+promotedUserStories.size());
                        System.debug('pus Keyset DestinationEnv: '+promotedUserStories.keySet());

                        // Add the Environments to the User Story Path
                        if(envNames.get(userStory.Environment__c) != null) {
                            Id currentEnvironmentId = userStory.Environment__c;
                            
                            // Iterate through the environments of the Deployment Flow Steps to get the future Environments
                            Integer currentStep = 0;
                            Integer futureEnvironments = 0;
                            if(envIds.get(currentEnvironmentId) != null) {
                                while (currentStep <= envNames.size()) {
                                    if (envIds.get(currentEnvironmentId) != null) {
                                        Id destinationId = envIds.get(currentEnvironmentId);
                                        if (destinationId != null && envBranches.containsKey(destinationId)) {
                                            targetBranch = targetBranch == null ?  envBranches.get(destinationId) : targetBranch;
                                        } else {
                                            targetBranch = targetBranch == null ? flowDetails.flow.Main_Branch__c : targetBranch;
                                        }
                                        if (envNames.get(destinationId) != null) {
                                            visualFlowSteps.add(new flowStepWrapper('slds-is-incomplete', envNames.get(destinationId)));
                                            futureEnvironments++;
                                        }
                                        currentEnvironmentId = destinationId;
                                    }
                                    currentStep += 1;
                                }
                            }

                            // Add the current environment
                            if(futureEnvironments > 0) {
                                visualFlowSteps.add(0, new flowStepWrapper('slds-is-current', envNames.get(userStory.Environment__c)));
                            } else {
                                visualFlowSteps.add(new flowStepWrapper('slds-is-complete slds-is-won', envNames.get(userStory.Environment__c)));
                            }
                            
                            // Iterate through the promotedUserStories to get the past Environments
                            Id destinationEnvironmentId = userStory.Environment__c;
                            while (promotedUSerStories.get(destinationEnvironmentId) != null) {
                                visualFlowSteps.add(0, new flowStepWrapper('slds-is-complete', promotedUSerStories.get(destinationEnvironmentId).Promotion__r.Source_Environment__r.Name));
                                destinationEnvironmentId = promotedUSerStories.get(destinationEnvironmentId).Promotion__r.Source_Environment__c;
                            }
                        }
                    }
                }

                if (flowDetails.isCBMFlow && flowStep != null) {
                    Set<String> userStoryFieldNameSet = new Set<String>{'Id', 'Name', Settings.ns+'User_Story_Title__c'};

                    userStoriesAhead = GlobalUtilities.getUserStoriesFromFieldsetAhead(userStoryFieldNameSet,flowStep);
                    if(userStory.Org_Credential__c != null && String.isNotBlank(userStory.Org_Credential__r.Org_Type__c) && !userStory.Org_Credential__r.Org_Type__c.contains('Scratch Org')) {
                        userStoriesBehind = GlobalUtilities.getUserStoriesFromFieldsetBehind(userStoryFieldNameSet, flowStep);
                        userStoriesAheadBehindTitle = ' - ' + userStoriesAhead.size() + ' ahead, ' + userStoriesBehind.size() + ' behind';
                    } else {
                        userStoriesBehind = new List<User_Story__c>();
                        userStoriesAheadBehindTitle = ' - ' + userStoriesAhead.size() + ' ahead';
                    }
                    Boolean isUserStoryAhead = false;
                    Map<Id, User_Story__c> userStoryMap = new Map<Id, User_Story__c>(userStoriesAhead);
                    if (userStoryMap.keySet().contains(userStory.Id)) {
                        isUserStoryAhead = true;
                    }
                    //userStoriesAheadBehindTitle = ' - ' + userStoriesAhead.size() + ' ahead, ' + userStoriesBehind.size() + ' behind';
                }
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    /*
        This is used to check if org has chatter enabled so chatter component is hidden
        and not rendered
     */
    public static Boolean getisChatterEnabled() {
        return Schema.SObjectType.User.isFeedEnabled() && Schema.SObjectType.User_Story__c.isFeedEnabled();
    }

    private static void checkForBackPromotedMetadata(Id usId) {
        List<User_Story_Metadata__c> metadatas = [SELECT Id, Status__c FROM User_Story_Metadata__c WHERE User_Story__c = :usId];
        for (User_Story_Metadata__c usm: metadatas) {
            if (usm.Status__c == Label.BACK_PROMOTED) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.BACK_PROMOTED_METADATA));
            }
        }
    }

    private static void checkForLastCommitNoChanges(Id usId) {
        List<User_Story_Commit__c> commits = [SELECT Id, Snapshot_Commit__r.Status__c FROM User_Story_Commit__c WHERE User_Story__c = :usId ORDER BY Snapshot_Commit__r.Commit_Date__c DESC LIMIT 1];
        if (!commits.isEmpty()) {
            if (commits[0].Snapshot_Commit__r.Status__c == 'No changes') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.COMMIT_NO_CHANGES));
            }
        }
    }
}