/**
 * Branch management VF page controller extension
 * @author Mert YALTI
 * @version 2.0
 */
public with sharing class BranchManagementExtension {

    private final Deployment_Flow__c deploymentflow;
    public Boolean hideCalcBackPromotionButtons { get; set; }
    public Boolean rebaselistView { get; set; }
    public Boolean showUserStories { get; set; }
    public Boolean promotionOnly { get; set; }
    public Boolean showCommits { get; set; }
    public Boolean hideCommitTab { get;set; }
    public Boolean showErrors { get; set; }
    public Boolean showFileDifferences { get; set; }
    public Boolean showAutoResolves { get; set; }
    public Boolean showMergeDifferences { get; set; }
    public Boolean showHiddenCheckboxes { get; set; }
    public Boolean enabledRebasePromotionPoller { get; set; }
    public Boolean rebaseDeploymentsCompleted { get; set; }
    public OverlayWrapper latestOverlay { get; set; }
    public Deployment_Flow_Step__c requestedStep { get; set; }
    public static String stepMapJSON { get; set; }
    @TestVisible private List<userStoryWrapper> usPlaceHolder { get; set; }
    /** View State issue resolution **/
    private List<errorWrapper> tempErrors;
    private List<Git_Org_Commit__c> tempCommits;

    public Integer errorSize { get; set; }

    /*********************************/
    public List<SelectOption> projects { get; set; }
    public List<SelectOption> releases { get; set; }
    public Integer allStorySize { get; set; }
    public Promotion__c promotion { get; set; }
    public String promotionBtnLabel { get; set; }
    public List<SelectOption> rebaseSourceEnvironments { get; set; }
    public String rebaseSource { get; set; }
    public String rebaseProject { get; set; }
    public String rebaseRelease { get; set; }
    public List<User_Story__c> dependenciesList { get; set; }
    public List<UserStoryWrapper> rebaseUserStoriesWrapper { get; set; }
    public List<RebaseEnvironmentWrapper> rebaseSources { get; set; }
    public Map<Id, Map<Id, RebaseSelectionsWrapper>> usEnvironmentAvailabilityMap { get; set; }
    public Map<Id, Promotion__c> rebasePromotionsMap { get; set; }
    public Boolean rebasePromotionsCreated { get; set; }
    private List<Promotion__c> rebasePromotions { get; set; }
    private Map<Id, List<Deployment_Flow_Step__c>> destinationToSources { get; set; }
    public Map<id,List<Environmental_Variable__c>> envId_envVarsMap {get{
        if(null == envId_envVarsMap){
            envId_envVarsMap = new Map<id,List<Environmental_Variable__c>>();
        }
        return envId_envVarsMap;
    }set;}
    public set<id> envIdsset {get{
        if(null == envIdsset) {
            envIdsset = new set<id>();
            for(Deployment_Flow_Step__c df:dfSteps){
                envIdsset.add(df.source_environment__c);
                envIdsset.add(df.destination_environment__c);
            }
        }
        return envIdsset;
    }private set;}
    private List<Deployment_Flow_Step__c> dfSteps {get{
        if(null == dfSteps){
            dfSteps = utilities.getStepDetailsOfDeploymentFlow(deploymentflow.id);
        }
        return dfSteps;
    }private set;}
    public List<Environmental_Variable__c> envVarList {get{
        if(null == envVarList){
            envVarList = new List<Environmental_Variable__c>([select id,name,value__c, environment__c, environment__r.name from Environmental_Variable__c where environment__c in:envIdsset order by name]);
            system.debug('envvarList in getter==> '+envVarList);
            List<Environmental_Variable__c> tempList;
            for(Environmental_Variable__c evItem:envVarList){
                tempList = new List<Environmental_Variable__c>();
                if(envId_envVarsMap.containsKey(evItem.environment__c)){
                    tempList = envId_envVarsMap.get(evItem.environment__c);
                }
                tempList.add(evItem);
                envId_envVarsMap.put(evItem.environment__c,tempList);
            }
        }
        return envVarList;
    }private set;}
    private String pathType { get; set; }
    private String stepResult { get; set; }

    public Integer commAhead { get; set; }
    public Integer commBehind { get; set; }

    // Added by Nahuel
    // return multiple keys.
    public String jobsManagerMatchingKeys {
        get {
            Deployment_Flow__c flow = [SELECT Id, Git_Repository__c FROM Deployment_Flow__c WHERE Id = :deploymentflow.Id];
            Map<Id, String> branchesPerEnv = Utilities.getEnvsAndBranchesOfDeploymentFlow(flow.Id);
            String m = '';
            for (String branch : branchesPerEnv.values()) {
                m += ';GIT-' + flow.Git_Repository__c + '-' + branch;
            }
            return m.replaceFirst(';', '');
        }
        set;
    }
    /**
     * Constructor method
     * @param  stdController Deployment_Flow__c Std controller
     * @see BranchManagementExtension.getAllStepDetails
     * @see resetPanels
     */
    public BranchManagementExtension(ApexPages.StandardController stdController) {
        hideCalcBackPromotionButtons = false;
        // Checking if branch management feature is enabled
        Boolean isFeatureEnabled = FeatureHelper.isFeatureEnabled('Branch Management');
        if (!isFeatureEnabled) {
            hideCalcBackPromotionButtons = true;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, 'The Branch Management feature is not enabled. Branch Management lets you achieve version control of all your Salesforce changes. Also, it lets you continuously test if branches are mergeable, keep Git & Salesforce orgs in sync, merge changes before deployment and, if working with Change Management, create feature branches per user story. To enable this feature, please contact support@copa.do.'));  // TODO: Change this error message to a custom label
        }
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) stdController.addFields(new List<String>(Schema.SObjectType.Deployment_Flow__c.fields.getMap().keySet()));

        rebaselistView = false; //has to be true change this before promote.
        showHiddenCheckboxes = false;
        rebasePromotionsCreated = false;
        rebaseDeploymentsCompleted = false;
        enabledRebasePromotionPoller = false;
        promotionOnly = true;
        if (rebasePromotionsMap == null) {
            rebasePromotionsMap = new Map<Id, Promotion__c>();
        } else if (rebasePromotionsMap.keySet().size() > 0) {
            rebasePromotionsCreated = true;
        }
        dependenciesList = new list<User_Story__c>();
        rebaseSources = new List<RebaseEnvironmentWrapper>();
        rebaseUserStoriesWrapper = new List<UserStoryWrapper>();
        this.deploymentflow = (Deployment_Flow__c) stdController.getRecord();
        system.debug('dfSteps==> '+dfSteps);
        system.debug('envIdsset==> '+envIdsset);
        system.debug('envVarList==> '+envVarList);
        system.debug('envId_envVarsMap==> '+envId_envVarsMap);

        Integer existingSteps = [select count() from Deployment_Flow_Step__c where
        Deployment_Flow__r.Active__c=true and
        (NOT Source_Environment__r.Type__c LIKE 'Scratch Org%') AND// MY: Added to exclude scratch orgs from used CBM licenses
        Deployment_Flow__r.Main_Branch__c!=null and
        Deployment_Flow__r.Git_Repository__c!=null and
        Branch__c!=null and Id !=:deploymentflow.Id ];

        LicenseManagerController lmc = new LicenseManagerController();
        System.debug(LoggingLevel.INFO,'***lmc.cbmBranchesAvailable :'+lmc.cbmBranchesAvailable);
        System.debug(LoggingLevel.INFO,'***existingSteps :'+existingSteps);
        if(lmc.cbmBranchesAvailable != null && existingSteps != null && lmc.cbmBranchesAvailable - existingSteps < 0){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.BRANCH_MGMT_LICENSE_EXCEEDED));
        }

        // Checking if the deployment flow is active or not
        if (!deploymentflow.Active__c) {
            hideCalcBackPromotionButtons = true;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, System.LABEL.DF_Inactive));
        }
        addWarnings(deploymentflow);
        promotion = new Promotion__c();
        BranchManagementExtension.getAllStepDetails(this.deploymentflow.Id);
        allStorySize = 0;
        resetPanels();
    }
    /**
     * This method is to be used to add warnings to help customers avoid mistakes
     * @param  Deployment flow record
     * @return Void, Should only add ApexPagesmessage
     */
    private void addWarnings(Deployment_Flow__c df) {
        if(Schema.getGlobalDescribe().get(Settings.ns+'Deployment_Flow__c').getDescribe().isAccessible()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Deployment Flow object is not accessible'));
            return;
        }
        //Warning: There is another Active Deployment Flow linked to the Same Git Repository + Name
        List<Deployment_Flow__c> dFlows = [SELECT Name FROM Deployment_Flow__c WHERE Git_Repository__c =: df.Git_Repository__c AND Active__c = TRUE AND Id !=: df.Id LIMIT 1];
        if(dFlows.size()>0){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, dFlows[0].Name+system.label.DF_Linked_To_Same_Repo));
        }
    }
    /**
     * Queries all deployment flow steps with their details
     * Marked as remote action since this particular function is in use at backDeploy JS resource
     * @param  flowId Deployment flow Id
     * @return        Map of steps
     */
    @RemoteAction
    public static Map<Id, Deployment_Flow_Step__c> getAllStepDetails(String flowId) {
        Map<Id, Deployment_Flow_Step__c> stepsMap = new Map<Id, Deployment_Flow_Step__c>();
        List<Deployment_Flow_Step__c> steps = Utilities.getStepDetailsOfDeploymentFlow(flowId);
        if (steps != null) {
            for (Deployment_Flow_Step__c dfs : steps) {
                stepsMap.put(dfs.Id, dfs);
            }
            steps.clear();
            stepMapJSON = JSON.serialize(stepsMap);
            System.debug(loggingLevel.Error, '*** stepMapJSON: ' + stepMapJSON);
            return stepsMap;
        } else {
            stepMapJSON = 'false';
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, LABEL.DF_NO_STEP));
            return stepsMap;
        }
    }
    /**
     * Resets all modal panel display states
     * @return [description]
     */
    public PageReference resetPanels() {
        if(latestOverlay != null){
            latestOverlay.userStories = new List<userStoryWrapper>();
            latestOverlay.errors = new List<errorWrapper>();
        }
        showUserStories = false;
        showCommits = false;
        showErrors = false;
        showFileDifferences = false;
        showAutoResolves = false;
        showMergeDifferences = false;
        return null;
    }
    /**
     * When the environment modal is closed all related variables needs to be reseted. This method handled that job.
     * @return null Pagereference
     */
    public PageReference resetModalsDOM() {
        latestOverlay = null;
        promotion = new Promotion__c();
        dependenciesList = new list<User_Story__c>();
        resetPanels();
        return null;
    }
    /**
     * To render user stories panel
     * @return null Pagereference
     */
    public PageReference showUserStories() {
        resetPanels();
        /*if(latestOverlay != null) {
        	latestOverlay.userStories.addAll(usPlaceHolder); // MY: Commented out since user stories should be loaded to the overlay when the end user selected either a project or a release
        }*/
        getUserStories();
        tempErrors = new List<ErrorWrapper>();
        showUserStories = true;
        return null;
    }
    /**
     * To render commits panel
     * @return null Pagereference
     */
    public PageReference showCommits() {
        resetPanels();
        if(latestOverlay != null) {
            latestOverlay.commitsAhead = commAhead;
            latestOverlay.commitsBehind = commBehind;
        }
        showCommits = true;
        return null;
    }
    /**
     * To render errors panel
     * @return null Pagereference
     */
    public PageReference showErrors() {
        resetPanels();
        if(latestOverlay != null) {
            retrieveErrors();
            latestOverlay.errors.addAll(tempErrors);
            tempErrors.clear();
            if(projects != null && !projects.isEmpty()){
                projects.clear();
            }
            if(releases != null && !releases.isEmpty()){
                releases.clear();
            }
            usPlaceHolder = new List<UserStoryWrapper>();
        }
        showErrors = true;
        return null;
    }
    /**
     * To render file differences panel
     * @return null Pagereference
     */
    public PageReference showFileDifferences() {
        resetPanels();
        if(latestOverlay != null) {
            if(projects != null && !projects.isEmpty()){
                projects.clear();
            }
            if(releases != null && !releases.isEmpty()){
                releases.clear();
            }
            usPlaceHolder = new List<UserStoryWrapper>();
            tempErrors = new List<ErrorWrapper>();
        }
        showFileDifferences = true;
        return null;
    }
    /**
     * To render auto resolved files panel
     * @return null Pagereference
     */
    public PageReference showAutoResolves() {
        resetPanels();
        if(latestOverlay != null) {
            if(projects != null && !projects.isEmpty()){
                projects.clear();
            }
            if(releases != null && !releases.isEmpty()){
                releases.clear();
            }
            usPlaceHolder = new List<UserStoryWrapper>();
            tempErrors = new List<ErrorWrapper>();
        }
        showAutoResolves = true;
        return null;
    }
    public PageReference showMergeDifferences() {
        resetPanels();
        showMergeDifferences = true;
        if(latestOverlay != null) {
            if(projects != null && !projects.isEmpty()){
                projects.clear();
            }
            if(releases != null && !releases.isEmpty()){
                releases.clear();
            }
            usPlaceHolder = new List<UserStoryWrapper>();
            tempErrors = new List<ErrorWrapper>();
        }
        return null;
    }
    public PageReference toggleRebaseListView() {
        showHiddenCheckboxes = showHiddenCheckboxes != true;
        return null;
    }
    public void resetRebaseModal() {
        rebaseSource = '';
        rebaseProject = '';
        rebaseRelease = '';
        projects = new List<SelectOption>();
        releases = new List<SelectOption>();
        rebaseSources = new List<RebaseEnvironmentWrapper>();
        rebaseUserStoriesWrapper = new List<UserStoryWrapper>();
    }

    private String getPageParameter(String paramName) {
        return String.isNotBlank(ApexPages.currentPage().getParameters().get(paramName)) ? ApexPages.currentPage().getParameters().get(paramName) : '';
    }
    @TestVisible
    private void calculateUserStoryEnvironmentAvailability(List<User_Story__c> usList) {

        Set<Id> usIds = new Set<Id>();
        for (User_Story__c us : usList) {
            usIds.add(us.Id);
        }
    }

    public Pagereference getRebaseUserStories() {
        if (rebaseProject == null && rebaseRelease == null) {
            projects = new List<SelectOption>();
            projects.add(new SelectOption('--None--', '--None--'));
            releases = new List<SelectOption>();
            releases.add(new SelectOption('--None--', '--None--'));
        }
        rebaseSources = new List<RebaseEnvironmentWrapper>();
        rebaseUserStoriesWrapper = new List<UserStoryWrapper>();
        List<Deployment_Flow_Step__c> rebaseSteps = new List<Deployment_Flow_Step__c>();
        Map<Id, String> uniqProjects = new Map<Id, String>();
        Map<Id, String> uniqReleases = new Map<Id, String>();
        if (rebaseSource == '--None--') {
            projects.clear();
            releases.clear();
            return null;
        }
        System.debug(loggingLevel.Error, '*** rebaseSource: ' + rebaseSource);
        for (Deployment_Flow_Step__c dfs : destinationToSources.get(rebaseSource)) {
            if ((rebaseProject != null && rebaseProject != '--None--') || (rebaseRelease != null && rebaseRelease != '--None--')) {
                rebaseSources.add(new RebaseEnvironmentWrapper(dfs));
            }
            rebaseSteps.add(dfs);
        }
        System.debug(loggingLevel.Error, '*** rebaseSteps: ' + rebaseSteps);
        usEnvironmentAvailabilityMap = new Map<Id, Map<Id, RebaseSelectionsWrapper>>();

        Map<Id, List<User_Story__c>> sourceEnvAndListUS = GlobalUtilities.getRebaseUserStories(deploymentflow.Id, rebaseSteps, rebaseSource);
        System.debug(loggingLevel.Error, '*** sourceEnvAndListUS: ' + sourceEnvAndListUS);
        List<User_Story__c> userStoryList = new List<User_Story__c>();
        Set<User_Story__c> userStorySet = new Set<User_Story__c>();
        Set<Id> processedEnvIds = new Set<Id>();
        System.debug(loggingLevel.Error, '*** destinationToSources.get(rebaseSource): ' + destinationToSources.get(rebaseSource));
        for (Deployment_Flow_Step__c dfs : destinationToSources.get(rebaseSource)) {
            if (sourceEnvAndListUS.containsKey(dfs.Source_Environment__c)) {
                for (User_Story__c us : sourceEnvAndListUS.get(dfs.Source_Environment__c)) {
                    userStorySet.add(us);
                    for (Deployment_Flow_Step__c t : destinationToSources.get(rebaseSource)) {
                        if (usEnvironmentAvailabilityMap.containsKey(t.Source_Environment__c)) {
                            Map<Id, RebaseSelectionsWrapper> tempMap = usEnvironmentAvailabilityMap.get(t.Source_Environment__c);
                            Boolean isTrueSource = dfs.Source_Environment__c != t.Source_Environment__c && !GlobalUtilities.rebasePromotedUserStoryDestinations.get(us.Id).contains(t.Source_Environment__c);
                            tempMap.put(us.Id, new RebaseSelectionsWrapper(t.Source_Environment__c, us.Id, isTrueSource, isTrueSource));
                            usEnvironmentAvailabilityMap.put(t.Source_Environment__c, tempMap);
                        } else {
                            Map<Id, RebaseSelectionsWrapper> tempMap = new Map<Id, RebaseSelectionsWrapper>();
                            Boolean isTrueSource = dfs.Source_Environment__c != t.Source_Environment__c && !GlobalUtilities.rebasePromotedUserStoryDestinations.get(us.Id).contains(t.Source_Environment__c);
                            tempMap.put(us.Id, new RebaseSelectionsWrapper(t.Source_Environment__c, us.Id, isTrueSource, isTrueSource));
                            usEnvironmentAvailabilityMap.put(t.Source_Environment__c, tempMap);
                        }
                    }
                }
            } else if (sourceEnvAndListUS.containsKey(rebaseSource)) {
                for (User_Story__c us : sourceEnvAndListUS.get(rebaseSource)) {
                    userStorySet.add(us);
                    for (Deployment_Flow_Step__c t : destinationToSources.get(rebaseSource)) {
                        if (usEnvironmentAvailabilityMap.containsKey(t.Source_Environment__c)) {
                            Map<Id, RebaseSelectionsWrapper> tempMap = usEnvironmentAvailabilityMap.get(t.Source_Environment__c);
                            Boolean isTrueSource = true;
                            tempMap.put(us.Id, new RebaseSelectionsWrapper(t.Source_Environment__c, us.Id, isTrueSource, isTrueSource));
                            usEnvironmentAvailabilityMap.put(t.Source_Environment__c, tempMap);
                        } else {
                            Map<Id, RebaseSelectionsWrapper> tempMap = new Map<Id, RebaseSelectionsWrapper>();
                            Boolean isTrueSource = true;
                            tempMap.put(us.Id, new RebaseSelectionsWrapper(t.Source_Environment__c, us.Id, isTrueSource, isTrueSource));
                            usEnvironmentAvailabilityMap.put(t.Source_Environment__c, tempMap);
                        }
                    }
                }
            }
            processedEnvIds.add(dfs.Id);
        }
        System.debug(loggingLevel.Error, '*** usEnvironmentAvailabilityMap: ' + usEnvironmentAvailabilityMap);
        userStoryList.addAll(userStorySet);
        for (User_Story__c us : userStoryList) {
            if (String.isBlank(rebaseProject) && String.isBlank(rebaseRelease)) {
                if (us.Project__c != null && !uniqProjects.containsKey(us.Project__c)) {
                    // Project & Release picklist values
                    projects.add(new SelectOption(us.Project__c, us.Project__r.Name));
                    uniqProjects.put(us.Project__c, us.Project__r.Name);
                }
                if (us.Release__c != null && !uniqReleases.containsKey(us.Release__c)) {
                    // Project & Release picklist values
                    releases.add(new SelectOption(us.Release__c, us.Release__r.Name));
                    uniqReleases.put(us.Release__c, us.Release__r.Name);
                }
            } else if ((rebaseProject != null && rebaseProject != '--None--' && us.Project__c == rebaseProject) || (rebaseRelease != null && rebaseRelease != '--None--' && us.Release__c == rebaseRelease)) {
                UserStoryWrapper temp = new UserStoryWrapper(us);
                System.debug(loggingLevel.Error, '*** us wrapper: ' + us);
                temp.isSelected = true;
                rebaseUserStoriesWrapper.add(temp);
            }

        }
        return null;
    }
    public Pagereference createRebasePromotionsAndDeploy() {
        isDeploy = TRUE;
        return createRebasePromotions();
    }
    public Boolean getIsRebasePromotionsCreated() {
        return rebasePromotionsCreated;
    }
    public Boolean getEnabledRebasePromotionPoller() {
        return enabledRebasePromotionPoller;
    }
    public Pagereference createRebasePromotions() {
        SavePoint sp = Database.setSavePoint();
        String fromEnvId = rebaseSource;
        Map<Id, User_Story__c> allUsMap = new Map<Id, User_Story__c>();
        System.debug(loggingLevel.Error, '*** rebaseUserStoriesWrapper: ' + rebaseUserStoriesWrapper);
        for (userStoryWrapper usw : rebaseUserStoriesWrapper) {
            allUsMap.put(usw.userStory.Id, usw.userStory);
        }
        if (rebasePromotions == null) {
            rebasePromotions = new List<Promotion__c>();
        }
        Boolean hasSelection = false;
        Boolean promotionOnly = true;
        //if (!selectedUserStories.isEmpty()) {
        Set<Id> processedEnvIds = new Set<Id>();
        Map<Id, List<User_Story__c>> envStories = new Map<Id, List<User_Story__c>>();
        System.debug(loggingLevel.Error, '*** usEnvironmentAvailabilityMap.keySet(): ' + usEnvironmentAvailabilityMap.keySet());
        for (Id envId : usEnvironmentAvailabilityMap.keySet()) {
            Boolean envHasSelection = false;
            Map<Id, RebaseSelectionsWrapper> pTemp = usEnvironmentAvailabilityMap.get(envId);
            System.debug(loggingLevel.Error, '*** pTemp: ' + pTemp);
            for (Id usId : pTemp.keySet()) {
                if (allUsMap.containsKey(usId) && allUsMap.get(usId) != null && pTemp.get(usId).isSelected) {
                    hasSelection = true;
                    envHasSelection = true;
                    if (envStories.containsKey(envId)) {
                        List<User_Story__c> usTemp = envStories.get(envId);
                        usTemp.add(allUsMap.get(usId));
                        envStories.put(envId, usTemp);
                    } else {
                        List<User_Story__c> usTemp = new List<User_Story__c>();
                        usTemp.add(allUsMap.get(usId));
                        envStories.put(envId, usTemp);
                    }
                }
            }
            if (processedEnvIds.contains(envId)) {
                continue;
            } else if (envHasSelection && !processedEnvIds.contains(envId)) {
                Promotion__c rebasePromotion = new Promotion__c();
                rebasePromotion.Back_Promotion__c = true;
                rebasePromotion.Source_Environment__c = null;
                rebasePromotion.Destination_Environment__c = envId;
                rebasePromotion.Project__c = rebaseProject != '--None--' ? rebaseProject : null;
                rebasePromotion.Release__c = rebaseRelease != '--None--' ? rebaseRelease : null;
                if (isDeploy) {
                    rebasePromotion.Status__c = 'Scheduled';
                }
                rebasePromotions.add(rebasePromotion);
            }
        }
        if (!hasSelection) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, System.LABEL.CBM2_at_least1_us));
        }
        System.debug(loggingLevel.Error, '*** rebasePromotions: ' + rebasePromotions);
        if (rebasePromotions.isEmpty()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, System.LABEL.CBM2_at_least1_us));
            return null;
        }

        try {
            System.debug(loggingLevel.Error, '*** envStories: ' + envStories);
            Utilities.Secure_DML(rebasePromotions, Utilities.DML_Action.UPS, schema.Sobjecttype.Promotion__c);
            Set<Id> rebasePromotionIds = new Set<Id>();
            for (Promotion__c pro : rebasePromotions) {
                if (envStories.containsKey(pro.Destination_Environment__c) && envStories.containsKey(pro.Destination_Environment__c)) {
                    addUserStoriesToPromotion(envStories.get(pro.Destination_Environment__c), pro);
                }
                rebasePromotionIds.add(pro.Id);
            }

            rebasePromotionsMap = new Map<Id, Promotion__c>();
            rebasePromotionsMap.putAll((List<Promotion__c>) Database.query(generatePromotionsSoql(rebasePromotionIds)));
            System.debug(loggingLevel.Error, '*** rebasePromotionsMap: ' + rebasePromotionsMap);
            if (rebasePromotionsMap.size() > 0) {
                rebasePromotionsCreated = true;
                if (isDeploy) {
                    enabledRebasePromotionPoller = true;
                    promotionOnly = false;
                }
            }
            System.debug(loggingLevel.Error, '*** rebasePromotionsCreated: ' + rebasePromotionsCreated);
            if (isDeploy) {
                promotionOnly = false;
                deployPromotions();
                rebasePromotions.clear();
            }
        } catch (Exception ex) {
            Database.rollback(sp);
            rebasePromotions.clear();
            allUsMap.clear();
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, ex.getMessage()));
        }

        return null;
    }
    private String generatePromotionsSoql(Set<Id> rebasePromotionIds) {
        //TODO : Below code will be enabled with v11 we need to include ManageBranchesDialog fieldset into package
        /*String promotionsSoql = 'SELECT ';
        for (Schema.FieldSetMember pf : SObjectType.Promotion__c.FieldSets.ManageBranchesDialog.getFields()) {
            promotionsSoql += pf.getFieldPath() + ', ';
        }*/
        String promotionsSoql = 'SELECT Name, Destination_Environment__c, Source_Environment__c, Project__c, Release__c, Status__c, ';
        promotionsSoql += 'Id FROM Promotion__c WHERE Id=:rebasePromotionIds LIMIT 999';
        return promotionsSoql;
    }
    public PageReference deployPromotions() {
        if (rebasePromotions.size() > 0) {
            promotionOnly = false;
            Set<Id> rebasePromotionIds = new Set<Id>();
            rebasePromotionsMap = new Map<Id, Promotion__c>();
            for (Promotion__c p : rebasePromotions) {
                p.Status__c = 'Scheduled';
                rebasePromotionIds.add(p.Id);
            }
            Utilities.Secure_DML(rebasePromotions, Utilities.DML_Action.UPD, schema.Sobjecttype.Promotion__c);
            rebasePromotionsMap.putAll((List<Promotion__c>) Database.query(generatePromotionsSoql(rebasePromotionIds)));
            rebasePromotionsCreated = true;
            enabledRebasePromotionPoller = true;
            for (Promotion__c pro : rebasePromotions) {
                if (!Test.isRunningTest()) {
                    DeployAPI.deployPromotionAsync(pro.Id, 'CBM Promotion ' + rebasePromotionsMap.get(pro.Id).Name, FALSE, FALSE, '');
                }
            }
            isDeploy = FALSE;
            rebasePromotions.clear();
        }
        return null;
    }
    public Integer rebasePromotionKeySize {
        get {
            Integer keys = 0;
            if (rebasePromotionsMap != null && rebasePromotionsMap.keySet().size() > 0) {
                keys = rebasePromotionsMap.keySet().size();
            }
            return keys;
        }
    }
    public PageReference goToPromotions() {
        rebasePromotionsCreated = true;
        showHiddenCheckboxes = false;
        return null;
    }
    public PageReference resetPromotions() {
        ApexPages.getMessages().clear();
        rebasePromotionsCreated = false;
        rebaseDeploymentsCompleted = false;
        enabledRebasePromotionPoller = false;
        showHiddenCheckboxes = false;
        resetRebaseModal();
        return null;
    }
    public PageReference checkRebasePromotionsStatuses() {
        //TODO : Below code will be enabled with v11 we need to include ManageBranchesDialog fieldset into package
        /*String promotionsSoql = 'SELECT ';
        for (Schema.FieldSetMember pf : SObjectType.Promotion__c.FieldSets.ManageBranchesDialog.getFields()) {
            promotionsSoql += pf.getFieldPath() + ', ';
        }*/
        Set<Id> promIds = rebasePromotionsMap.keySet();
        String promotionsSoql = 'SELECT Name, Destination_Environment__c, Source_Environment__c, Project__c, Release__c, Status__c, ';
        promotionsSoql += 'Id FROM Promotion__c WHERE Id=:promIds AND Status__c != \'Cancelled\' LIMIT 999';
        rebasePromotionsMap = new Map<Id, Promotion__c>();
        List<Promotion__c> proList = new List<Promotion__c>();
        proList.addAll((List<Promotion__c>) Database.query(promotionsSoql));
        Integer completedPromotionCount = 0;
        for (Promotion__c pro : proList) {
            rebasePromotionsMap.put(pro.Id, pro);
            if (pro.Status__c.contains('Completed')) {
                completedPromotionCount++;
            }
        }
        if (proList.size() == completedPromotionCount) {
            resetPromotions();
            rebaseDeploymentsCompleted = true;
        }
        proList.clear();
        return null;
    }
    /**
     * ONGOING DEVELOPMENT
     * @return [description]
     */
    public Pagereference prepareRebase() {
        resetRebaseModal();
        promotionBtnLabel = 'Back Promotion';
        Map<Id, Integer> stepAsDestinationCount = new Map<Id, Integer>();
        Map<Id, String> stepAsDestination = new Map<Id, String>();
        destinationToSources = new Map<Id, List<Deployment_Flow_Step__c>>();
        Map<Id, Deployment_Flow_Step__c> tempStepsMap = BranchManagementExtension.getAllStepDetails(deploymentflow.Id);
        Map<Id, Deployment_Flow_Step__c> rebaseSourceSteps = getMultipleStepDetails(tempStepsMap.keySet());
        for (Deployment_Flow_Step__c dfs : rebaseSourceSteps.values()) {
            if (stepAsDestinationCount.containsKey(dfs.Destination_Environment__c)) {
                Integer count = stepAsDestinationCount.get(dfs.Destination_Environment__c);
                stepAsDestinationCount.put(dfs.Destination_Environment__c, count + 1);
            } else if (dfs.Destination_Environment__c != null) {
                stepAsDestinationCount.put(dfs.Destination_Environment__c, 1);
            }

            if (destinationToSources.containsKey(dfs.Destination_Environment__c)) {
                stepAsDestination.put(dfs.Destination_Environment__c, dfs.Id);
                List<Deployment_Flow_Step__c> temp = destinationToSources.get(dfs.Destination_Environment__c);
                if(dfs.Source_Environment__r.Type__c != null && !dfs.Source_Environment__r.Type__c.contains('Scratch Org')) {
                    temp.add(dfs);
                }
                destinationToSources.put(dfs.Destination_Environment__c, temp);
            } else if (dfs.Destination_Environment__c != null) {
                stepAsDestination.put(dfs.Destination_Environment__c, dfs.Id);
                List<Deployment_Flow_Step__c> temp = new List<Deployment_Flow_Step__c>();
                if(dfs.Source_Environment__r.Type__c != null && !dfs.Source_Environment__r.Type__c.contains('Scratch Org')) {
                    temp.add(dfs);
                }
                destinationToSources.put(dfs.Destination_Environment__c, temp);
            }
        }
        rebaseSourceEnvironments = new List<SelectOption>();
        rebaseSourceEnvironments.add(new SelectOption('--None--', '--None--'));
        for (Id destId : stepAsDestinationCount.keySet()) {
            if (stepAsDestinationCount.get(destId) >= 1) {
                rebaseSourceEnvironments.add(new SelectOption(destId, rebaseSourceSteps.get(stepAsDestination.get(destId)).Destination_Environment__r.Name));
            }
        }
        return null;
    }

    /**
     * Prepares the modal with the deployment flow results.json
     * @see getStepDetails
     * @return null Pagereference
     */
    public PageReference prepareOverlay() {
        promotionBtnLabel = 'Promotion';
        if (promotion != null) {
            promotion.Project__c = null;
            promotion.Release__c = null;
        }
        pathType = '';
        stepResult = '';

        // following variables are passed from the VF page
        String fromEnvId = getPageParameter('fromEnvId');
        if(!Schema.getGlobalDescribe().get(Settings.ns+'Environment__c').getDescribe().isAccessible()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Environment object is not accessible'));
            return null;
        }
        List<Environment__c> environmentList = [Select Type__c From Environment__c Where Id =: String.escapeSingleQuotes(fromEnvId) Limit 1];
        if(!environmentList.isEmpty()){
            hideCommitTab = environmentList.get(0).Type__c != null && environmentList.get(0).Type__c.contains('Scratch org') ? false : true;
            environmentList.clear();
        }
        String toEnvId = getPageParameter('toEnvId');
        String stepId = getPageParameter('stepId');
        pathType = getPageParameter('type');
        stepResult = getPageParameter('stepResult');

        requestedStep = getStepDetails(stepId);
        if (requestedStep != null) {
            latestOverlay = null;
            String envId = fromEnvId;
            Datetime lastSync = requestedStep.Last_Merge_CBM_Sync__c;
            if (pathType == 'pull') {
                envId = toEnvId;
                promotionBtnLabel = 'Back Promotion';
                lastSync = requestedStep.Last_Pull_CBM_Sync__c;
            }

            latestOverlay = new OverlayWrapper(fromEnvId, toEnvId, requestedStep.Source_Environment__r.Name, requestedStep.Destination_Environment__r.Name, pathType, tempCommits, new List<errorWrapper>(), ApexPages.currentPage().getParameters().get('stepId'));
        }
        return null;
    }
    /**
     * Process the modal with the deployment flow step results.json
     * @return null Pagereference
     */
    public PageReference errorsOverlay() {
        retrieveErrors();
        errorSize = tempErrors.size();
        System.debug('**f**errorSize : ' + errorSize);
        tempErrors.clear();
        return null;
    }
    public PageReference retrieveErrors() {
        if (requestedStep != null) {
            tempErrors = new List<errorWrapper>();

            // Processing step details
            // stepResults comes from the result.json attachment stored on the deployment flow step
            if (!String.isBlank(stepResult)) {
                Map<String, Object> jsonObject = (Map<String, Object>) JSON.deserializeUntyped(stepResult);
                if (pathType == 'merge') {
                    // Merge errors
                    List<Object> mergeValidationErrors = (List<Object>) jsonObject.get('mergeValidationErrors');
                    tempErrors = processErrorJSON(pathType, mergeValidationErrors);
                } else {
                    // Pull errors
                    List<Object> pullValidationErrors = (List<Object>) jsonObject.get('pullValidationErrors');
                    tempErrors = processErrorJSON(pathType, pullValidationErrors);
                }
                System.debug(loggingLevel.Error, '*** tempErrors: ' + tempErrors);
            }
        }
        return null;
    }
    /**
     * Finishes the modal with user stories ahead or behind
     * @return null Pagereference
     */
    public PageReference userStoriesOverlay() {
        try {
            getOnlyUserStoriesNumber();
        } catch (Exception e) {
            System.debug(loggingLevel.Error, '*** ERROR userStoriesOverlay: ' + e.getMessage());
        }
        return null;
    }
    /**
     * Retrieves user stories that are ready to be promoted
     * @return [description]
     */
    public PageReference getPromotableUserStories() {
        if (!usPlaceHolder.isEmpty() && latestOverlay != null) {
            latestOverlay.userStories = new List<userStoryWrapper>();
            for (userStoryWrapper usw : usPlaceHolder) {
                if ((usw.userStory.Project__c != null && usw.userStory.Project__c == promotion.Project__c) || (usw.userStory.Release__c != null && usw.userStory.Release__c == promotion.Release__c)) {
                    latestOverlay.userStories.add(usw);
                }
            }
            return null;
        }
        return null;
    }
    /**
     * Gets all user stories depending on the operation type
     * if merge retrieves user stories ahead,
     * if pull retrieve user stories behind
     */
    @TestVisible
    private void getOnlyUserStoriesNumber() {
        if (latestOverlay != null) {
            usPlaceHolder = new List<userStoryWrapper>();
            if (latestOverlay.pathType == 'merge') {
                for (User_Story__c ustry : GlobalUtilities.getUserStoriesAhead(requestedStep)) {
                    usPlaceHolder.add(new userStoryWrapper(ustry));
                }
            } else {
                for (User_Story__c ustry : GlobalUtilities.getUserStoriesBehind(requestedStep)) {
                    usPlaceHolder.add(new userStoryWrapper(ustry));
                }
            }
            allStorySize = usPlaceHolder.size();
            usPlaceHolder.clear();
        } else {
            System.debug(loggingLevel.Error, '*** latestOverlay cannot be null in order to retrieve proper user story list: ');
        }
    }
    /**
     * Gets all user stories depending on the operation type
     * if merge retrieves user stories ahead,
     * if pull retrieve user stories behind
     */
    @TestVisible
    private void getUserStories() {
        projects = new List<SelectOption>();
        Map<Id, String> uniqProjects = new Map<Id, String>();
        releases = new List<SelectOption>();
        Map<Id, String> uniqReleases = new Map<Id, String>();
        if (latestOverlay != null) {
            usPlaceHolder = new List<userStoryWrapper>();
            projects.add(new SelectOption('', '-- None --'));
            releases.add(new SelectOption('', '-- None --'));

            Schema.DescribeSObjectResult dsr = Schema.getGlobalDescribe().get(Settings.ns+'User_Story__c').getDescribe();
            Map<String, Schema.SObjectField> fieldMap = dsr.fields.getMap();
            Schema.FieldSet fieldSetObj = dsr.FieldSets.getMap().get(Settings.ns+'CBM_Fields');

            Set<String> availableFieldsSet = new Set<String>();
            for (Schema.FieldSetMember field : fieldSetObj.getFields()) {
                availableFieldsSet.add(field.getFieldPath());
            }

            if (latestOverlay.pathType == 'merge') {
                for (User_Story__c ustry : GlobalUtilities.getUserStoriesFromFieldsetAhead(availableFieldsSet,requestedStep)) {
                    usPlaceHolder.add(new userStoryWrapper(ustry));
                    if (ustry.Project__c != null && !uniqProjects.containsKey(ustry.Project__c)) {
                        // Project & Release picklist values
                        projects.add(new SelectOption(ustry.Project__c, ustry.Project__r.Name));
                        uniqProjects.put(ustry.Project__c, ustry.Project__r.Name);
                    }
                    if (ustry.Release__c != null && !uniqReleases.containsKey(ustry.Release__c)) {
                        // Project & Release picklist values
                        releases.add(new SelectOption(ustry.Release__c, ustry.Release__r.Name));
                        uniqReleases.put(ustry.Release__c, ustry.Release__r.Name);
                    }
                }
            } else {
                for (User_Story__c ustry : GlobalUtilities.getUserStoriesFromFieldsetBehind(availableFieldsSet,requestedStep)) {
                    usPlaceHolder.add(new userStoryWrapper(ustry));
                    if (ustry.Project__c != null && !uniqProjects.containsKey(ustry.Project__c)) {
                        // Project & Release picklist values
                        projects.add(new SelectOption(ustry.Project__c, ustry.Project__r.Name));
                        uniqProjects.put(ustry.Project__c, ustry.Project__r.Name);
                    }
                    if (ustry.Release__c != null && !uniqReleases.containsKey(ustry.Release__c)) {
                        // Project & Release picklist values
                        releases.add(new SelectOption(ustry.Release__c, ustry.Release__r.Name));
                        uniqReleases.put(ustry.Release__c, ustry.Release__r.Name);
                    }
                }
            }
            allStorySize = usPlaceHolder.size();
            uniqProjects.clear();
            uniqReleases.clear();
        } else {
            System.debug(loggingLevel.Error, '*** latestOverlay cannot be null in order to retrieve proper user story list: ');
        }
    }
    private List<errorWrapper> processErrorJSON(String pathType, List<Object> errorObject) {
        if (errorObject != null) {
            List<errorWrapper> tempList = new List<errorWrapper>();
            for (Object e : errorObject) {
                Map<String, Object> file = (Map<String, Object>) e;
                tempList.add(new ErrorWrapper(pathType, (String) file.get('l'), (String) file.get('m'), (String) file.get('t')));
                if (tempList.size() >= 1000) break;
            }
            return tempList;
        }
        return new List<errorWrapper>();
    }
    private Deployment_Flow_Step__c getStepDetails(String stepId) {
        try {
            Map<String, String> d = GlobalUtilities.getAllFieldsWithoutSharing('Deployment_Flow_Step__c');
            //Typecasting and escaping single quotes needs to resolve SOQL Injection issue since both of them are actual sanity check methods for dynamic queries.
            String injectionSecureId = String.escapeSingleQuotes(String.valueOf(stepId));
            String soqlString = 'SELECT ' + String.escapeSingleQuotes(d.get(Label.FIELDS)) + ',Source_Environment__r.Name, Destination_Environment__r.Name FROM ' + String.escapeSingleQuotes(d.get(Label.OBJECT)) + ' WHERE Id =:injectionSecureId';
            return Database.query(soqlString);
        } catch (Exception e) {

            System.debug(loggingLevel.Error, '*** getStepDetails Exception : ' + e.getMessage());
            return null;
        }
    }

    private Map<Id, Deployment_Flow_Step__c> getMultipleStepDetails(Set<Id> stepIds) {
        Map<Id, Deployment_Flow_Step__c> dfsMap = new Map<Id, Deployment_Flow_Step__c>();
        try {
            Map<String, String> d = GlobalUtilities.getAllFieldsWithoutSharing('Deployment_Flow_Step__c');
            System.debug(loggingLevel.Error, '*** stepIds: ' + stepIds);
            String soqlString = 'SELECT ' + String.escapeSingleQuotes(d.get(Label.FIELDS)) + ',Source_Environment__r.Name, Destination_Environment__r.Name, Source_Environment__r.Type__c FROM ' + String.escapeSingleQuotes(d.get(Label.OBJECT)) + ' WHERE Id IN: stepIds';
            System.debug(loggingLevel.Error, '*** Database.query(soqlString): ' + Database.query(soqlString));
            for (Deployment_Flow_Step__c dfs : Database.query(soqlString)) {
                dfsMap.put(dfs.Id, dfs);
            }
            return dfsMap;
        } catch (Exception e) {
            System.debug(loggingLevel.Error, '*** getMultipleStepDetails Exception : ' + e.getMessage());
            return dfsMap;
        }
    }
// place holder for future releases
    /*public static List<Git_Org_Commit__c> getCommits(String envId, DateTime dateFrom) {
        return [SELECT Name, Org__c, Git_Backup__c, Status__c, Commit_Date__c, View_in_Git__c, Commit_Message__c, Changes__c FROM Git_Org_Commit__c WHERE Org__c = : envId AND Commit_Date__c > : dateFrom AND Status__c = 'Complete'];
    }*/
    private Boolean isDeploy = FALSE;
    public PageReference createPromotionAndDeploy() {
        isDeploy = TRUE;
        return createPromotion();
    }
    public PageReference createPromotion() {

        String fromEnvId = latestOverlay.fromEnvId;
        String toEnvId = latestOverlay.toEnvId;
        List<User_Story__c> selectedUserStories = new List<User_Story__c>();
        for (userStoryWrapper usw : latestOverlay.userStories) {
            if (usw.isSelected) {
                selectedUserStories.add(usw.userStory);
            }
        }
        if (!selectedUserStories.isEmpty()) {
            System.debug('### Creating promotion');
            promotion.Source_Environment__c = fromEnvId;
            promotion.Send_Deployment_Complete_email__c = true;
            if (latestOverlay.pathType == 'pull') {
                promotion.Back_Promotion__c = true;
                promotion.Source_Environment__c = null;
                promotion.Destination_Environment__c = toEnvId;
            }
            try {
                Utilities.Secure_DML(promotion, Utilities.DML_Action.INS, schema.Sobjecttype.Promotion__c);
                System.debug('### Creating User Story Promotion');
                addUserStoriesToPromotion(selectedUserStories, promotion);
                if (isDeploy) {
                    if (!Test.isRunningTest()) {
                        DeployAPI.deployPromotionAsync(promotion.Id, 'CBM Promotion ' + [SELECT Name FROM Promotion__c WHERE Id = :promotion.Id LIMIT 1].Name, FALSE, FALSE, '');
                    }
                    isDeploy = FALSE;
                }
                PageReference promotionRef = new PageReference('/' + promotion.Id);
                promotion = new Promotion__c();
                return promotionRef;
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, e.getMessage()));
            }
            return null;
        } else {
            System.debug('### Nothing to Create promotion');
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, System.LABEL.CBM2_at_least1_us));
            return null;
        }
    }
    /**
     * Calculates on the fly the dependencies
     */
    public PageReference calculateUSDependencies() {
        system.debug('calculateUSDependencies');
        dependenciesList = new list<User_Story__c>();
        if (latestOverlay.pathType != 'pull') {
            set<Id> usIds = new set<Id>();
            for (userStoryWrapper usw : latestOverlay.userStories) {
                if (usw.isSelected) {
                    usIds.add(usw.userStory.Id);
                }
            }
            if (usIds.size() > 0) {
                dependenciesList = GlobalUtilities.getUserStoriesDependencies(usIds, latestOverlay.toEnvId);
            }
        }
        return null;
    }

    private static void addUserStoriesToPromotion(List<User_Story__c> usl, Promotion__c p) {
        List<Promoted_User_Story__c> uspl = new List<Promoted_User_Story__c>();
        for (User_Story__c us : usl) {
            Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = us.Id, Promotion__c = p.Id);
            pus.Name = 'Promoted User Story: ' + us.Name;
            uspl.add(pus);
        }
        Utilities.Secure_DML(uspl, Utilities.DML_Action.INS, schema.Sobjecttype.Promoted_User_Story__c);
    }

    public PageReference addPageMessages() {
        String message = ApexPages.currentPage().getParameters().get('message');
        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, message));
        return null;
    }

    public class OverlayWrapper {
        public String fromEnvId { get; set; }
        public String fromEnvName { get; set; }
        public String toEnvId { get; set; }
        public String toEnvName { get; set; }
        public String pathType { get; set; }
        public List<userStoryWrapper> userStories { get; set; }
        //public List<Git_Org_Commit__c> commits {get; set;}
        public Integer commitsAhead { get; set; }
        public Integer commitsBehind { get; set; }

        public List<ErrorWrapper> errors { get; set; }
        public String stepId { get; set; }

        public OverlayWrapper(String fromEnvId, String toEnvId, String fromEnvName, String toEnvName, String pathType, List<Git_Org_Commit__c> commits, List<ErrorWrapper> errors, String stepId) {
            this.fromEnvId = fromEnvId;
            this.toEnvId = toEnvId;
            this.fromEnvName = fromEnvName;
            this.toEnvName = toEnvName;
            this.pathType = pathType;
            this.userStories = new List<userStoryWrapper>();
            //this.commits = commits;
            this.errors = errors;
            this.stepId = stepId;
            this.commitsAhead = 0;
            this.commitsBehind = 0;
        }
    }
    public class RebaseEnvironmentWrapper {
        public Boolean isSelected { get; set; }
        public Deployment_Flow_Step__c step { get; set; }
        public rebaseEnvironmentWrapper(Deployment_Flow_Step__c step) {
            this.isSelected = true;
            this.step = step;
        }
    }
    public class UserStoryWrapper {
        public Boolean isSelected { get; set; }
        public User_Story__c userStory { get; set; }
        public userStoryWrapper(User_Story__c userStory) {
            this.isSelected = false;
            this.userStory = userStory;
        }
    }
    public class RebaseSelectionsWrapper {
        public String rebaseEnv { get; set; }
        public String rebaseUs { get; set; }
        public Boolean isSelected { get; set; }
        public Boolean isAvailable { get; set; }
        public rebaseSelectionsWrapper(String rebaseEnv, String rebaseUs, Boolean isSelected, Boolean isAvailable) {
            this.rebaseEnv = rebaseEnv;
            this.rebaseUs = rebaseUs;
            this.isSelected = isSelected;
            this.isAvailable = isAvailable;
        }
    }
    public class FilesWrapper implements Comparable {
        public String pathType { get; set; }
        public String dmlType { get; set; }
        public String metadataName { get; set; }
        public FilesWrapper(String pathType, String dmlType, String metadataName) {
            this.pathType = pathType;
            this.dmlType = dmlType;
            this.metadataName = metadataName;
        }

        public Integer compareTo(Object compareTo) {
            FilesWrapper t = (FilesWrapper) compareTo;
            if (t.dmlType + t.metadataName == this.dmlType + this.metadataName) return 0;
            if (t.dmlType + t.metadataName > this.dmlType + this.metadataName) return -1;
            return 1;
        }
    }
    public class ErrorWrapper {
        public String pathType { get; set; }
        public String level { get; set; }
        public String errorMessage { get; set; }
        public String copadoTip { get; set; }
        public ErrorWrapper(String pathType, String level, String errorMessage, String copadoTip) {
            this.pathType = pathType;
            this.level = level;
            this.errorMessage = errorMessage;
            this.copadoTip = copadoTip;
        }
    }
}