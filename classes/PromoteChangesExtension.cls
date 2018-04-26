public with sharing class PromoteChangesExtension {
    public Promotion__c promotion {get; set;}
    //public List<Schema.FieldSetMember> promotionRelatedList {get; set;}

    public List<userStoryWrapper> userStories {get; set;}
    public List<promotedStoryWrapper> promotedWrappedStories {get; set;}
    @Testvisible private Set<Id> promotedIdsSet {get; set;}
    //public ApexPages.Standardcontroller controller {get; set;}
    public Boolean renderStep1 {get; set;}
    public Boolean renderBtnPromote {get; set;}
    public String branch {get; set;}
    public boolean enableCreateDeploymentButton {get; set;}
    public String promotedUserStoryIds {get; set;}
    public Boolean isCSTEnabled {get; set;}
    public Decimal sourceEnvMaxSCAScore {get; set;}
    public GlobalUtilities.deploymentFlowDetails flowDetails {get; set;}

    //public List<Selenium_Test_Group__c> sourceUserStorySeleniumTests {get; set;}
    //public List<Selenium_Test_Group__c> sourceRegressionSeleniumTests {get; set;}
    //public List<Selenium_Test_Group__c> destinationUserStorySeleniumTests {get; set;}
    //public List<Selenium_Test_Group__c> destinationRegressionSeleniumTests {get; set;}

    public seleniumTestResultWrapper str {get; set;}

    public Decimal worstSCAscore {get; set;}
    public Decimal averageSCAscore {get; set;}
    //public Map<Id, Decimal> userStoryScore {get; set;}
    public Promoted_User_Story__c mockStoryWrapper {get; set;}
    public Boolean scaAccess {get; set;}
    public Boolean openCreateDeployment {get;set;}
    //User Story Dependencies
    public list<User_Story__c> dependenciesList {get; set;}

    public String deploymentPrefix {
        get {
            if (!String.isBlank(deploymentPrefix)) {
                return deploymentPrefix;
            }
            Map<String, Schema.SObjectType> m  = Schema.getGlobalDescribe();
            Schema.SObjectType s = m.get(Settings.ns + 'Deployment__c');
            Schema.DescribeSObjectResult r = s.getDescribe() ;
            return r.getKeyPrefix();
        }
        set;
    }

    public PromoteChangesExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) stdController.addFields(Utilities.getAllFields('Promotion__c').get(Label.FIELDS).split(','));
        if (!Test.isRunningTest()) stdController.addFields(new List<String>{Settings.ns + 'Release__r.Name'});
        if (!Test.isRunningTest()) stdController.addFields(new List<String>{Settings.ns + 'Source_Environment__r.Name'});
        if (!Test.isRunningTest()) stdController.addFields(new List<String>{Settings.ns + 'Destination_Environment__r.Name'});

        scaAccess = FeatureAccessHelper.isSCAFeatureAccessible();
        promotedIdsSet = new Set<Id>();
        renderBtnPromote = false;
        renderStep1 = true;
        //controller = stdController;

        this.promotion = Utilities.getPromotionById(stdController.getId());
        if (this.promotion == null) {
            this.promotion = new Promotion__c();
        }
        //promotionRelatedList = SObjectType.User_Story__c.FieldSets.PromotionRelatedList.getFields();
        refreshTables();
        getSeleniumTestGroups();
        List<Environment__c> sourceEnv = [SELECT Maximum_SCA_Score__c FROM Environment__c WHERE Id = :promotion.Source_Environment__c];
        if (sourceEnv.size() > 0 && sourceEnv[0].Maximum_SCA_Score__c != null) {
            sourceEnvMaxSCAScore = sourceEnv[0].Maximum_SCA_Score__c;
        } else {
            sourceEnvMaxSCAScore = 0;
        }

        // Get URL createDeployment parameter
        String createDeployment = ApexPages.currentPage().getParameters().get('createDeployment');
        openCreateDeployment = createDeployment != null && Boolean.valueOf(createDeployment);
        ApexPages.currentPage().getParameters().remove('createDeployment');

        //calculateSCAscores();
    }
    /*public void calculateSCAscores () {

        Integer stories = 0;
        Decimal totalScore = 0;
        worstSCAscore = 0;
        averageSCAscore = 0;
        for (Id usId : userStoryScore.keySet()) {
            totalScore += userStoryScore.get(usId);
            stories += 1;
            if (worstSCAscore < userStoryScore.get(usId)) {
                worstSCAscore = userStoryScore.get(usId);
                mockStoryWrapper = new Promoted_User_Story__c(User_Story__c = usId);
            }
        }
        if (totalScore > 0 && stories > 0) {
            averageSCAscore = totalScore / stories;
        }
    }*/
    public PageReference reloadPromotion() {
        PageReference ref =  Page.PromoteChanges;
        ref.getParameters().put('id', promotion.Id);
        ref.setRedirect(true);
        return ref;
    }
    public PageReference openResolveConflictsPage() {
        PageReference ref =  Page.ResolveConflicts;
        ref.getParameters().put('promotionId', promotion.Id);
        ref.setRedirect(true);
        return ref;
    }
    public void refreshTables() {
        promotedIdsSet = new Set<Id>();
        if (LicenseHelper.isLicensesExceeded()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.LICENSES_EXCEEDED));
            return;
        }
        promotedWrappedStories = getPromotedUserStories();
        userStories = listUserStories();
        if (!promotion.Back_Promotion__c) {
            dependenciesList = GlobalUtilities.getUserStoriesDependencies(promotedIdsSet, promotion.Destination_Environment__c);
        }
    }

    public void gotoAddUserStories() {
        listUserStories();
    }
    public List<promotedStoryWrapper> getPromotedUserStories() {
        Map<Id, Decimal> userStoryScore = new Map<Id, Decimal>();
        promotedWrappedStories = new List<promotedStoryWrapper>();
        String queryFields = '';
        for (Schema.FieldSetMember f : SObjectType.User_Story__c.FieldSets.PromotionRelatedList.getFields()) {
            if(f != null){
                queryFields += ', User_Story__r.' + f.getFieldPath();
            }
        }
        List<Promoted_User_Story__c> tmp =  Database.query(' SELECT Id, User_Story__c ' + queryFields + ' FROM Promoted_User_Story__c WHERE Promotion__c = \'' + promotion.Id + '\'');
        //[select Id, User_Story__c, User_Story__r.Name, User_Story__r.Status__c, User_Story__r.User_Story_Title__c , User_Story__r.Epic__c, User_Story__r.Epic__r.Epic_Title__c, Promotion__c from Promoted_User_Story__c where Promotion__c=:promotion.Id];
        for (Promoted_User_Story__c pus : tmp) {
            promotedWrappedStories.add(new promotedStoryWrapper(false, pus));
            promotedIdsSet.add(pus.User_Story__c);
        }
        if (!validateDeployment() && enableCreateDeploymentButton == true) {
            enableCreateDeploymentButton = false;
        }

        if (promotedWrappedStories.size() == 0) {
            gotoAddUserStories();
        }
        enableCreateDeploymentButton = promotedIdsSet.size() > 0;

        updatePromotedIdSetToString();
        for (Static_Code_Analysis_Result__c scar : [SELECT Score_v11__c, User_Story__c FROM Static_Code_Analysis_Result__c WHERE User_Story__c IN :promotedIdsSet ORDER BY CreatedDate ASC]) {
            userStoryScore.put(scar.User_Story__c, scar.Score_v11__c);
        }

        // calculate SCA score
        Integer stories = 0;
        Decimal totalScore = 0;
        worstSCAscore = 0;
        averageSCAscore = 0;
        for (Id usId : userStoryScore.keySet()) {
            totalScore += userStoryScore.get(usId);
            stories += 1;
            if (worstSCAscore < userStoryScore.get(usId)) {
                worstSCAscore = userStoryScore.get(usId);
                mockStoryWrapper = new Promoted_User_Story__c(User_Story__c = usId);
            }
        }
        if (totalScore > 0 && stories > 0) {
            averageSCAscore = totalScore / stories;
        }
        // end of calculate SCA score

        return promotedWrappedStories;
    }
    public List<userStoryWrapper> listUserStories() {
        userStories = new List<userStoryWrapper>();
        Set<String> fieldNameSet = new Set<String>();
        String queryFields = '';
        for (Schema.FieldSetMember f : SObjectType.User_Story__c.FieldSets.PromotionRelatedList.getFields()) {
            queryFields += ',' + f.getFieldPath();
            fieldNameSet.add(f.getFieldPath());
        }

        if (!promotion.Back_Promotion__c) {
            List<User_Story__c> lusProject = new List<User_Story__c>();
            List<User_Story__c> lusRelease = new List<User_Story__c>();

            if (promotion.Project__c != null) {
                lusProject = Database.query(' SELECT Id ' + queryFields + ' FROM User_Story__c WHERE Promote_Change__c=true ' +
                        ' AND Environment__c = \'' + promotion.Source_Environment__c + '\'' +
                        ' AND Project__c = \'' + promotion.Project__c + '\' Limit 999');

                for (User_Story__c us : lusProject) {
                    if (!promotedIdsSet.contains(us.Id)) {
                        userStories.add(new userStoryWrapper(false, us));
                    }
                }
            } else if (promotion.Release__c != null ) {
                lusRelease = Database.query(' SELECT Id ' + queryFields + ' FROM User_Story__c WHERE Promote_Change__c=true ' +
                        ' AND Environment__c = \'' + promotion.Source_Environment__c + '\'' +
                        ' AND Release__c = \'' + promotion.Release__c + '\' Limit 999' );

                for (User_Story__c us : lusRelease) {
                    if (!promotedIdsSet.contains(us.Id)) {
                        userStories.add(new userStoryWrapper(false, us));
                    }
                }
            }
        } else {
            List<Deployment_FLow_Step__c> flowStep = [SELECT Deployment_Flow__c, Source_Environment__c, Source_Environment__r.Name, Branch__c, Destination_Environment__c, Destination_Environment__r.Name, Last_MErge_Base__c, Last_Merge_CBM_Sync__c, Last_Pull_CBM_Sync__c, Destination_Branch__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :flowDetails.flow.Id AND Source_Environment__c = :promotion.Destination_Environment__c];
            //for (User_Story__c userStory : GlobalUtilities.getUserStoriesBehind(flowStep)) {

            Set<String> usIdSet = new Set<String>();
            if(!flowStep.isEmpty()){
                for(User_Story__c userStory : GlobalUtilities.getUserStoriesFromFieldsetBehind(fieldNameSet,flowStep.get(0))){
                    usIdSet.add(userStory.Id);
                }
            }

            List<User_Story__c> newUserStoryList = Database.query(' SELECT Id ' + queryFields + ' FROM User_Story__c WHERE Id IN : usIdSet');

            for (User_Story__c userStory : newUserStoryList){
                if (!promotedIdsSet.contains(userStory.Id) && userStories.size() < 999) {
                    userStories.add(new userStoryWrapper(false, userStory));
                }
            }
        }

        return userStories;
    }
    public void removeSelectedUserStories() {
        List<Promoted_User_Story__c> removals = new List<Promoted_User_Story__c>();
        for (promotedStoryWrapper pus : promotedWrappedStories) {
            if (pus.selected) {
                removals.add(new Promoted_User_Story__c(Id = pus.promotedUS.Id));
            }
        }
        Utilities.Secure_DML(removals, Utilities.DML_Action.DEL, schema.Sobjecttype.Promoted_User_Story__c);
        refreshTables();
        getSeleniumTestGroups();
    }
    public void addStoriesToPromotion() {
        // check if there is any userStories
        if ( userStories == null || userStories.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.NO_USER_STORIES_TO_PROMOTE));
            return;
        }
        // review the database status so no duplicate records are created
        List<Promoted_User_Story__c> tmp =  Database.query(' SELECT User_Story__c FROM Promoted_User_Story__c WHERE Promotion__c = \'' + promotion.Id + '\'');
        for (Promoted_User_Story__c pus : tmp) {
            promotedIdsSet.add(pus.User_Story__c);
        }
        //Check promotedWrappedStories and add them to the promotedIdsSet
        for (promotedStoryWrapper pusw : promotedWrappedStories) {
            if (!promotedIdsSet.contains(pusw.promotedUS.User_Story__c)) {
                promotedIdsSet.add(pusw.promotedUS.User_Story__c);
            }
        }

        Integer selcount = 0;
        List<Promoted_User_Story__c> promotedStories = new List<Promoted_User_Story__c>();
        for (userStoryWrapper usw : userStories) {
            if (usw.selected ) {
                selcount++;
            }
        }
        if (selcount == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.NO_USER_STORIES_TO_PROMOTE));
            return;
        }
        for (userStoryWrapper usw : userStories) {
            if (usw.selected) {
                selcount++;
                System.debug('*** promotedIdsSet.contains(usw.userStory.Id)'+promotedIdsSet.contains(usw.userStory.Id));
                if (!promotedIdsSet.contains(usw.userStory.Id)) {
                    promotedIdsSet.add(usw.userStory.Id);
                    String userStoryTitle = (!String.isBlank(usw.userStory.User_Story_Title__c)) ? usw.userStory.User_Story_Title__c : '';
                    if (userStoryTitle.length() > 80) {
                        userStoryTitle = userStoryTitle.left(80);
                    }
                    promotedStories.add(new Promoted_User_Story__c(Name = userStoryTitle, User_Story__c = usw.userStory.Id, Promotion__c = promotion.Id));
                }
            }
        }
        System.debug('*** promotedStories : '+ promotedStories);
        Utilities.Secure_DML(promotedStories, Utilities.DML_Action.INS, schema.Sobjecttype.Promoted_User_Story__c);
        refreshTables();
        getSeleniumTestGroups();
    }
    public void updatePromotedIdSetToString() {
        promotedUserStoryIds = '';
        for (String s : promotedIdsSet) {
            promotedUserStoryIds += (promotedUserStoryIds == '' ? '' : ',') + s;
        }
    }
    public class promotedStoryWrapper {
        public boolean selected {get; set;}
        public Promoted_User_Story__c promotedUS {get; set;}
        public promotedStoryWrapper(boolean b, Promoted_User_Story__c pus) {
            this.selected = b;
            this.promotedUS = pus;
        }
    }
    public class userStoryWrapper {
        public boolean selected {get; set;}
        public User_Story__c userStory {get; set;}
        public userStoryWrapper(boolean b, User_Story__c us) {
            this.selected = b;
            this.userStory = us;
        }
    }
    public class seleniumTestWrapper {
        public String location {get; set;}
        public Selenium_Test_Group__c testGroup {get; set;}
        public seleniumTestWrapper(String location, Selenium_Test_Group__c stg) {
            this.location = location;
            this.testGroup = stg;
        }
    }
    public class seleniumTestResultWrapper {
        public Integer countAllSourceRegression {get; set;}
        public Integer countFinishedSourceRegression {get; set;}
        public Integer countErrorsSourceRegression {get; set;}

        public Integer countAllDestinationRegression {get; set;}
        public Integer countFinishedDestinationRegression {get; set;}
        public Integer countErrorsDestinationRegression {get; set;}

        public Integer countAllSourceUserStory {get; set;}
        public Integer countFinishedSourceUserStory {get; set;}
        public Integer countErrorsSourceUserStory {get; set;}

        public Integer countAllDestinationUserStory {get; set;}
        public Integer countFinishedDestinationUserStory {get; set;}
        public Integer countErrorsDestinationUserStory {get; set;}

        public seleniumTestResultWrapper() {
            this.countAllSourceRegression = 0;
            this.countFinishedSourceRegression = 0;
            this.countErrorsSourceRegression = 0;

            this.countAllDestinationRegression = 0;
            this.countFinishedDestinationRegression = 0;
            this.countErrorsDestinationRegression = 0;

            this.countAllSourceUserStory = 0;
            this.countFinishedSourceUserStory = 0;
            this.countErrorsSourceUserStory = 0;

            this.countAllDestinationUserStory = 0;
            this.countFinishedDestinationUserStory = 0;
            this.countErrorsDestinationUserStory = 0;
        }
    }
    public boolean validateDeployment() {
        Boolean isSandboxDestinations = false;
        /*if (LicenseHelper.isLicensesExceeded()) {
            System.debug('**f**lisans : ');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.LICENSES_EXCEEDED));
            return false;
        }*/

        Promotion__c p = [SELECT Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c, Release__r.Base_Branch__c FROM Promotion__c WHERE Id = :promotion.Id];
        List<String> extraFields = new List<String>();
        extraFields.add(Settings.ns + 'Git_Repository__r.Pull_Request_Base_URL__c');
        extraFields.add(Settings.ns + 'Git_Repository__r.Git_Provider__c');
        if (p.Project__r.Deployment_Flow__c != null) {
            flowDetails = GlobalUtilities.getDeploymentFlowDetails(p.Project__r.Deployment_Flow__c, String.Join(extraFields,', '));
        } else if (p.Release__r.Project__r.Deployment_Flow__c != null) {
            flowDetails = GlobalUtilities.getDeploymentFlowDetails(p.Release__r.Project__r.Deployment_Flow__c, String.join(extraFields,', '));
        }
        Boolean isCCMFlow = flowDetails.flow.Git_Repository__c == null && flowDetails.flow.Main_Branch__c == null;

        if (promotion != null && (LicenseHelper.isCopadoEnabled() || LicenseHelper.isCCMEnabled())) {
            // Base Branch Validation
            if(p.Release__r.Base_Branch__c != null) {
                String userStoryList = '';
                for(User_Story__c us : [SELECT Id, Name, Base_Branch__c FROM User_Story__c WHERE Id IN (SELECT User_Story__c FROM Promoted_User_Story__c WHERE Promotion__c = :p.Id) AND Base_Branch__c != null AND Base_Branch__c != :p.Release__r.Base_Branch__c LIMIT 1000]) {
                    if(!String.isBlank(userStoryList)) {
                        userStoryList += ', ';
                    }
                    userStoryList += us.Name;
                }
                if(!String.isBlank(userStoryList)){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.PROMOTION_BASE_BRANCH_CONFLICT + ' ' + userStoryList));
                }
            }

            // CCM Only user validation
            if (!LicenseHelper.isCopadoEnabled() && LicenseHelper.isCCMEnabled()) {
                for (Environment__c destinationEnv : [SELECT Id, Type__c FROM Environment__c WHERE Id = :promotion.Destination_Environment__c]) {
                    if (destinationEnv.Type__c == 'Sandbox') {
                        isSandboxDestinations = true;
                    } else {
                        isSandboxDestinations = false;
                        break;
                    }
                }
                if (!isSandboxDestinations) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CCM_DESTINATION_ORG_INVALID));
                    return false;
                }
            }

            if (flowDetails.flow.Active__c) {
                System.debug('flow: ' + flowdetails);
                System.debug('isCBMFlow: ' + flowDetails.isCBMFlow);
                if (LicenseHelper.isCopadoEnabled() && isCCMFlow) {
                    return true;
                } else if (flowDetails.isCBMFlow) {
                    return true;
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CBM_FLOW_INVALID));
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.PROMOTION_FLOW_INACTIVE));
            }
        } else if (LicenseHelper.isCopadoEnabled()) {
            return true;
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED));
        }
        return false;
    }

    public boolean getIsSeleniumRunning() {
        List<String> ids = new List<String>();
        for (seleniumTestWrapper a : getSeleniumTestGroups())
            if (a.testGroup.Status__c == 'Queued' || a.testGroup.Status__c == 'In Progress') {
                return true;
            }
        return false;
    }
    public PageReference recalcSeleniumTestGroups() {
        getSeleniumTestGroups();
        PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
        pageRef.setRedirect(true);
        return pageRef;
    }
    public void refreshSeleniumTestGroups() {
        getSeleniumTestGroups();
    }

    public List<seleniumTestWrapper> getSeleniumTestGroups() {
        isCSTEnabled = false;
        for (Feature__c feature : [SELECT Name, Enabled__c FROM Feature__c]) {
            if (feature.Name == 'Selenium Testing' && feature.Enabled__c == true) {
                isCSTEnabled = true;
            }
        }

        List<seleniumTestWrapper> seleniumTests = new List<seleniumTestWrapper>();
        //sourceUserStorySeleniumTests = new List<Selenium_Test_Group__c>();
        //sourceRegressionSeleniumTests = new List<Selenium_Test_Group__c>();
        //destinationUserStorySeleniumTests = new List<Selenium_Test_Group__c>();
        //destinationRegressionSeleniumTests = new List<Selenium_Test_Group__c>();

        str = new seleniumTestResultWrapper();

        List<Selenium_Test_Group__c> stgs = new List<Selenium_Test_Group__c>();
        List<Id> usTestGroupIds = new List<Id>();

        if (!promotion.Back_Promotion__c) {
            for (User_Story_Selenium_Test__c usST : [SELECT Selenium_Test_Group__c FROM User_Story_Selenium_Test__c WHERE User_Story__c IN :promotedIdsSet AND (User_Story__r.Environment__c = :promotion.Source_Environment__c OR User_Story__r.Environment__c = :promotion.Destination_Environment__c)]) {
                usTestGroupIds.add(usST.Selenium_Test_Group__c);
            }
        } else {
            for (User_Story_Selenium_Test__c usST : [SELECT Selenium_Test_Group__c FROM User_Story_Selenium_Test__c WHERE User_Story__c IN :promotedIdsSet]) {
                usTestGroupIds.add(usST.Selenium_Test_Group__c);
            }
        }

        for (Selenium_Test_Group__c rSTG : [SELECT Id, Name, Environment__c, Environment__r.Name, Type__c, Status__c, Status_Icon__c, Status_Date__c FROM Selenium_Test_Group__c WHERE Id IN :usTestGroupIds OR (Type__c = 'Regression Test' AND (Environment__c = :promotion.Source_Environment__c OR Environment__c = :promotion.Destination_Environment__c))]) {
            stgs.add(rSTG);
        }

        /*for (Selenium_Test_Group__c usSTG : [SELECT Id, Name, Environment__c, Environment__r.Name, Type__c, Status__c, Status_Icon__c, Status_Date__c FROM Selenium_Test_Group__c WHERE Id IN :usTestGroupIds]) {
            stgs.add(usSTG);
        }*/


        System.debug('#SeleniumTestGroups.size(): ' + stgs.size());
        for (Selenium_Test_Group__c tg : stgs) {
            if (tg.Environment__c == promotion.Source_Environment__c) {
                if (tg.Type__c == 'Regression Test') {
                    //sourceRegressionSeleniumTests.add(tg);
                    str.countAllSourceRegression += 1;
                    if (tg.Status__c != null) {
                        str.countFinishedSourceRegression += tg.Status__c.startsWith('Completed') ? 1 : 0;
                        str.countFinishedSourceRegression += tg.Status__c.startsWith('Fail') ? 1 : 0;
                        str.countErrorsSourceRegression += tg.Status__c.containsIgnoreCase('Error') || tg.Status__c.contains('Fail') ? 1 : 0;
                    }
                }
                if (tg.Type__c == 'User Story Test') {
                    //sourceUserStorySeleniumTests.add(tg);
                    str.countAllSourceUserStory += 1;
                    if (tg.Status__c != null) {
                        str.countFinishedSourceUserStory += tg.Status__c.startsWith('Completed') ? 1 : 0;
                        str.countFinishedSourceUserStory += tg.Status__c.startsWith('Fail') ? 1 : 0;
                        str.countErrorsSourceUserStory += tg.Status__c.containsIgnoreCase('Error') || tg.Status__c.contains('Fail') ? 1 : 0;
                    }
                }
                seleniumTests.add(new seleniumTestWrapper('Source', tg));
            } else if (tg.Environment__c == promotion.Destination_Environment__c) {
                if (tg.Type__c == 'Regression Test') {
                    //destinationRegressionSeleniumTests.add(tg);
                    str.countAllDestinationRegression += 1;
                    if (tg.Status__c != null) {
                        str.countFinishedDestinationRegression += tg.Status__c.startsWith('Completed') ? 1 : 0;
                        str.countFinishedDestinationRegression += tg.Status__c.startsWith('Fail') ? 1 : 0;
                        str.countErrorsDestinationRegression += tg.Status__c.containsIgnoreCase('Error') || tg.Status__c.contains('Fail') ? 1 : 0;
                    }
                }
                if (tg.Type__c == 'User Story Test') {
                    //destinationUserStorySeleniumTests.add(tg);
                    str.countAllDestinationUserStory += 1;
                    if (tg.Status__c != null) {
                        str.countFinishedDestinationUserStory += tg.Status__c.startsWith('Completed') ? 1 : 0;
                        str.countFinishedDestinationUserStory += tg.Status__c.startsWith('Fail') ? 1 : 0;
                        str.countErrorsDestinationUserStory += tg.Status__c.containsIgnoreCase('Error') || tg.Status__c.contains('Fail') ? 1 : 0;
                    }
                }
                seleniumTests.add(new seleniumTestWrapper('Destination', tg));
            }
        }
        return seleniumTests;
    }

    private PageReference runTestsSourceRegressionAll(integer environment, integer groupoftests) {
        integer i = RunTestGroupsBatch.runSeleniumTestsOfPromotionId(promotion.Id, environment, groupoftests);
        if (i == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.PROMOTION_RUN_NO_TESTS));
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.PROMOTION_RUN_RUNNING));
        }
        return null;
    }

    public PageReference runTestsSourceRegression() {
        return runTestsSourceRegressionAll(RunTestGroupsBatch.ENV_SOURCE, RunTestGroupsBatch.MODE_REGRESSION_ONLY);
    }

    public PageReference runTestsSourceUserStory() {
        return runTestsSourceRegressionAll(RunTestGroupsBatch.ENV_SOURCE, RunTestGroupsBatch.MODE_USERSTORY_ONLY);
    }

    public PageReference runTestsDestinationRegression() {
        return runTestsSourceRegressionAll(RunTestGroupsBatch.ENV_DEST, RunTestGroupsBatch.MODE_REGRESSION_ONLY);
    }

    public PageReference runTestsDestinationUserStory() {
        return runTestsSourceRegressionAll(RunTestGroupsBatch.ENV_DEST, RunTestGroupsBatch.MODE_USERSTORY_ONLY);
    }

    public List<User_Story_Metadata__c> getUserStoryMetadatas() {
        List<User_Story_Metadata__c> userStoryMetadatas = new List<User_Story_Metadata__c>();
        Integer limitHeapSize = Limits.getLimitHeapSize();
        Integer maxMetadataHeapSize = 0;
        Integer limitCPUTime = Limits.getLimitCpuTime();
        Integer maxCPUTime = 0;

        if (promotedIdsSet.size() > 0 && Schema.SObjectType.User_Story_Metadata__c.isAccessible()) {
            try {
                for (User_Story_Metadata__c usMetadata : [SELECT Name, Status_Icon__c, Metadata_API_Name__c, Status__c, LastModifiedDate, User_Story__c, User_Story__r.Name FROM User_Story_Metadata__c WHERE User_Story__c IN : promotedIdsSet ORDER BY Metadata_API_Name__c, User_Story__r.Name DESC LIMIT 999]) {
                    Integer startingHeap = Limits.getHeapSize();
                    Integer startingCpuTime = Limits.getCpuTime();
                    if ((startingHeap + maxMetadataHeapSize * 2) > limitHeapSize || (startingCpuTime + maxCPUTime * 2) > limitCPUTime) {
                        System.debug('### Heap Size limit reached. Exit User Story Metadata for loop.');
                        break;
                    }
                    userStoryMetadatas.add(usMetadata);

                    Integer addedHeap = Limits.getHeapSize() - startingHeap;
                    Integer addedCpuTime = Limits.getCpuTime() - startingCpuTime;
                    if (addedHeap > maxMetadataHeapSize) {
                        maxMetadataHeapSize = addedHeap;
                    }
                    if (addedCpuTime > maxCPUTime) {
                        maxCPUTime = addedCpuTime;
                    }
                }
            } catch (Exception e) {
                System.debug(e);
            }
        }
        System.debug('usMetadatas size: ' + userStoryMetadatas.size());
        return userStoryMetadatas;
    }

    public String jobsManagerMatchingKeys {
        get {
            Map<Id, String> branchesPerEnv = new Map<Id, String>();
            Promotion__c p = [SELECT Project__c, Release__c, Project__r.Deployment_Flow__c,
                    Project__r.Deployment_Flow__r.Active__c,
                    Project__r.Deployment_Flow__r.Git_Repository__c,
                    Destination_Org_Credential__r.Environment__c
            FROM Promotion__c WHERE Id = :promotion.Id];
            if (p.Project__r.Deployment_Flow__c == null || p.Destination_Org_Credential__r.Environment__c == null) {
                return '';
            }
            branchesPerEnv = getEnvsAndBranchesOfDeploymentFlow(p.Project__r.Deployment_Flow__c);
            branch = '';
            if (branchesPerEnv.containsKey(p.Destination_Org_Credential__r.Environment__c)) {
                branch = branchesPerEnv.get(p.Destination_Org_Credential__r.Environment__c);
            }
            //String m = 'Promotion-'+p.Destination_Org_Credential__r.Environment__c;
            return 'GIT-' + p.Project__r.Deployment_Flow__r.Git_Repository__c + '-' + branch;
        }
        set;
    }

    public static Map<Id, String> getEnvsAndBranchesOfDeploymentFlow(Id dfId) {
        Map<Id, String> envsAndBranches = new Map<Id, String>(); // Env.Id, Branch_name
        Deployment_Flow__c df = [SELECT Id, Name, Git_Repository__c, Main_Branch__c FROM Deployment_Flow__c WHERE Id = :dfId];
        List<Deployment_Flow_Step__c> steps = [SELECT Source_Environment__c, Branch__c, Destination_Environment__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :df.Id];
        if (steps.size() > 0) {
            for (Deployment_Flow_Step__c step : steps) {
                if (step.Source_Environment__c != null) {
                    envsAndBranches.put(step.Source_Environment__c, step.Branch__c);
                }
            }
            // any dest environment not previously set as a source somewhere, is the main env, and matches the main branch.
            for (Deployment_Flow_Step__c step : steps) {
                if (step.Destination_Environment__c != null && !envsAndBranches.containsKey(step.Destination_Environment__c) ) {
                    envsAndBranches.put(step.Destination_Environment__c, df.Main_Branch__c);
                }
            }
        }
        return envsAndBranches;
    }

    /*
        This is used to check if org has chatter enabled so chatter component is hidden
        and not rendered
     */
    public static Boolean getisChatterEnabled() {
        return Schema.SObjectType.User.isFeedEnabled() && Schema.SObjectType.Promotion__c.isFeedEnabled();
    }
}