public without sharing class UserStoryTriggerHelper {
    private static Map<Id, Sprint__c> mapSprint;
    private static Map<Id, Org__c> orgMap;
    public static List<User_Story__c> promoteAndDeployedStories = new List<User_Story__c>();
    public static Map<Id, Environment__c> environmentMap;
    public static Map<Id, Release__c> releaseMap;

    public static void prepareMaps() {
        if (Trigger.isDelete)return;

        Set<Id> setSprintIds = new Set<Id>();
        Set<Id> oids = new Set<Id>();
        Set<Id> envids = new Set<Id>();
        Set<Id> releaseIds = new Set<Id>();
        for (SObject so : Trigger.new) {
            User_Story__c us = (User_Story__c)so;
            setSprintIds.add(us.Sprint__c);
            oids.add(us.org_credential__c);
            if (us.Environment__c != null) {
                envIds.add(us.Environment__c);
            }
            if (us.Release__c != null) {
                releaseIds.add(us.Release__c);
            }
        }

        orgMap = new Map<Id, Org__c>([select Id, OwnerId, Environment__c from Org__c where Id IN :oids]);
        for (Org__c org : orgMap.values()) {
            envIds.add(org.Environment__c);
        }
        environmentMap = new Map<Id, Environment__c>([SELECT Id, Minimum_Apex_Test_Coverage__c FROM Environment__c WHERE Id IN :envIds]);

        releaseMap = new Map<Id, Release__c>([SELECT Id, Base_Branch__c FROM Release__c WHERE Id IN :releaseIds]);

        mapSprint = new Map<Id, Sprint__c>([select Id, Project__c from Sprint__c where Id in :setSprintIds]);
        if (Trigger.isUpdate) {
            for (SObject so : Trigger.old) {
                User_Story__c old = (User_Story__c)so;
                User_Story__c usNew = (User_Story__c)Trigger.newMap.get(so.Id);
                if (old.Sprint__c == null) {
                    if (usNew.Sprint__c != null && usNew.Project__c == null) {
                        usNew.Project__c = mapSprint.get(usNew.Sprint__c).Project__c;
                    }
                }
            }
        }
    }
    public static void checkSprints(User_Story__c oldUs, User_Story__c us) {
        if (oldUs != null && (oldUs.Status__c == 'Backlog' || oldUs.Status__c == 'Backburner') && us.Status__c == oldUs.Status__c && oldUs.Sprint__c == null && us.Sprint__c != null) {
            us.Status__c = 'Approved';
        } else if ((us.Status__c == 'Backlog' || us.Status__c == 'Backburner') && us.Sprint__c != null) {
            us.Sprint__c = null;
        }
    }
    public static void validateOrgEnvironmentRelationship(User_Story__c us) {
        Org__c org = orgMap.get(us.Org_Credential__c);
        if (us.Org_Credential__c != null && us.Environment__c != null && org.Environment__c != us.Environment__c) {
            us.addError('The org credential must belong to the environment');
        }
    }
    public static void setEnvironment(User_Story__c us) {
        if (us.Environment__c == null && us.Org_Credential__c != null) {
            us.Environment__c = orgMap.get(us.Org_Credential__c).Environment__c;
        }
        if (us.Environment__c != null && environmentMap.get(us.Environment__c) != null) {
            Environment__c env = environmentMap.get(us.Environment__c);
            if (us.Minimum_Apex_Code_Coverage__c < env.Minimum_Apex_Test_Coverage__c)us.Minimum_Apex_Code_Coverage__c = env.Minimum_Apex_Test_Coverage__c;
        }
    }
    public static void setProject(User_Story__c usNew) {
        if (usNew.Sprint__c != null && usNew.Project__c == null) {
            usNew.Project__c = mapSprint.get(usNew.Sprint__c).Project__c;
        }
    }
    public static void setBaseBranch(User_Story__c us) {
        if (us.Release__c != null && String.isBlank(us.Base_Branch__c)) {
            Release__c release = releaseMap.get(us.Release__c);
            if(release != null && release.Base_Branch__c != null && !String.isBlank(release.Base_Branch__c)) {
                us.Base_Branch__c = release.Base_Branch__c;
            }
        }
    }
    public static void addUserStoryToPromoteDeployQueue(User_Story__c ous, User_Story__c nus) {
        if (ous.Promote_and_Deploy__c == false && nus.Promote_and_Deploy__c == true) {
            promoteAndDeployedStories.add(nus);
        }
    }
    public static void promoteAndDeployUserStories() {
        for (User_Story__c us : promoteAndDeployedStories) {
            createPromotion(us);
        }
    }

    private static void createPromotion(User_Story__c us) {
        System.debug('### Creating promotion');
        Promotion__c promotion = new Promotion__c(Project__c = us.Project__c);
        promotion.Release__c = us.Release__c;
        promotion.Source_Org_Credential__c = us.Org_Credential__c;
        promotion.Source_Environment__c = us.Environment__c;
        promotion.Send_Deployment_Complete_email__c = true;
        try {
            Utilities.Secure_DML(promotion, Utilities.DML_Action.INS, schema.Sobjecttype.Promotion__c);
            System.debug('### Creating User Story Promotion');
            addUserStoryToPromotion(us, promotion);
            DeployAPI.deployPromotionAsync(promotion.Id, us.Name, us.Validate_Only__c, us.Promote_as_Single_Step__c, us.Promotion_Test_Level__c);
        } catch (Exception e) {
            system.debug(e.getMessage());//#ToRemove
            us.addError(returnValidationError(e.getMessage()));
        }
    }


    private static String returnValidationError(String m) {
        if (m.contains(Label.COPADO_DEPLOYER_CCM_LICENSE_NOT_ENABLED))return Label.COPADO_DEPLOYER_CCM_LICENSE_NOT_ENABLED;
        if (m.contains(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED))return Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED;
        if (m.contains(Label.PROMOTION_FLOW_INACTIVE))return Label.PROMOTION_FLOW_INACTIVE;
        if (m.contains(Label.CCM_DESTINATION_ORG_INVALID) && m.contains(Label.CBM_FLOW_INVALID))return Label.CCM_DESTINATION_ORG_INVALID + ' ' + Label.CBM_FLOW_INVALID;
        if (m.contains(Label.CCM_DESTINATION_ORG_INVALID))return Label.CCM_DESTINATION_ORG_INVALID;
        if (m.contains(Label.CBM_FLOW_INVALID))return Label.CBM_FLOW_INVALID;
        return m;
    }
    private static void addUserStoryToPromotion(User_Story__c us, Promotion__c p) {
        Promoted_User_Story__c pus = new Promoted_User_Story__c(User_Story__c = us.Id, Promotion__c = p.Id);
        pus.Name = 'Promoted User Story: ' + us.Name;
        Utilities.Secure_DML(pus, Utilities.DML_Action.INS, schema.Sobjecttype.Promoted_User_Story__c);
    }
}