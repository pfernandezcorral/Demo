public without sharing class PromotionTriggerHelper {
    public static Map<Id,List<Deployment_Flow_Step__c>> stepsMap;
    private static Map<Id,List<Org__c>> environmentOrgMap;
    private static Map<Id,Org__c> orgMap;
    public static Map<Id,Id> projectFlowMap;
    public static Map<Id,GlobalUtilities.deploymentFlowDetails> promotionFlows;
    public static Map<Id,Id> releaseProjectsMap;
    public static Map<Id,String> destinationEnvironmentTypesMap;
    private static Set<Id> promotionIds = new Set<Id>();
    public static List<Promotion__c> completedPromotions = new List<Promotion__c>();
    public static Map<Id,Set<String>> promotionMetadatasMap;
    public static Map<Id,Set<User_Story_Metadata__c>> environmentsMetadatasMap;
    public static Set<Id> destinationEnvironmentsIds;
    public static List<User_Story_Metadata__c> usMetadataUpd;
    public static Map<Id,Boolean> environmentIndexBackPromotionMap;

    public static void isCompleted(Promotion__c pnew){
        if(pNew.Status__c=='Completed')promotionIds.add(pNew.Id);
    }
    public static void resetUserStories(){
        List<User_Story__c> userStories = new List<User_Story__c>();
        List<Promoted_User_Story__c> promotedStories = [Select Id, User_Story__c, Promotion__c, Promotion__r.Destination_Environment__c, promotion__r.Destination_Org_Credential__c, Promotion__r.Back_Promotion__c from Promoted_User_Story__c where Promotion__c IN :promotionIds];
        for(Promoted_User_Story__c pus : promotedStories){
            if(!pus.Promotion__r.Back_Promotion__c)userStories.add(new User_Story__c(Id = pus.User_Story__c,Promote_Change__c = false, Promote_and_deploy__c = false, Environment__c = pus.Promotion__r.Destination_Environment__c, Org_Credential__c = pus.Promotion__r.Destination_Org_Credential__c));
        }
        Utilities.Secure_DML(userStories, Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story__c);
    }
    public static void prepareData(List<SObject> records){
        stepsMap = new Map<Id,List<Deployment_Flow_Step__c>>();
        projectFlowMap = new Map<Id,Id>();
        promotionFlows = new Map<Id,GlobalUtilities.deploymentFlowDetails>();
        releaseProjectsMap = new Map<Id,Id>();
        environmentOrgMap = new Map<Id,List<Org__c>>();
        destinationEnvironmentTypesMap = new Map<Id,String>(); // Id, Type__c
        orgMap = new Map<Id,Org__c>();
        Set<Id> flowIds = new Set<Id>();
        Set<Id> environmentSetIds = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();
        Set<Id> releaseIds = new Set<Id>();
        promotionMetadatasMap = new Map<Id,Set<String>>();
        environmentsMetadatasMap = new Map<Id,Set<User_Story_Metadata__c>>();
        destinationEnvironmentsIds = new Set<Id>();
        usMetadataUpd = new List<User_Story_Metadata__c>();
        environmentIndexBackPromotionMap = new Map<Id,Boolean>();
        
        for(SObject o : records){
            Promotion__c p = (Promotion__c)o;
            if(p.Release__c != null)releaseIds.add(p.Release__c);
            if(p.Project__c != null)projectIds.add(p.Project__c);
            if(p.Source_Environment__c !=null)environmentOrgMap.put(p.source_environment__c, new List<Org__c>());
            if(p.destination_environment__c!=null) {
                environmentOrgMap.put(p.destination_environment__c, new List<Org__c>());
                destinationEnvironmentsIds.add(p.destination_environment__c);
            }
        }

        for (Environment__c env: [SELECT Id, Index_Back_Promotion_metadata__c FROM Environment__c WHERE Id IN :destinationEnvironmentsIds]) {
            environmentIndexBackPromotionMap.put(env.Id, env.Index_Back_Promotion_metadata__c);
        }
        
        List<Release__c> releases = [SELECT Project__c FROM Release__c WHERE Id IN :releaseIds];
        for (Release__c rel: releases) {
            projectIds.add(rel.Project__c);
            releaseProjectsMap.put(rel.Id, rel.Project__c);
        }
        
        for(Project__c p : [select Id, Deployment_Flow__c FROM Project__c where Id IN :projectIds]){
            flowIds.add(p.Deployment_Flow__c);
            projectFlowMap.put(p.Id, p.Deployment_Flow__c);
            stepsMap.put(p.Deployment_Flow__c, new List<Deployment_Flow_Step__c>());
            if(p.Deployment_Flow__c != null)promotionFlows.put(p.Id, GlobalUtilities.getDeploymentFlowDetails(p.Deployment_Flow__c, ''));
        }
        List<Deployment_Flow_Step__c> steps = [select Id, Source_Environment__c, Destination_Environment__c, Source_Environment__r.Type__c, Destination_Environment__r.Type__c, Deployment_Flow__c from Deployment_Flow_Step__c where Deployment_Flow__c IN :flowIds];
        for(Deployment_Flow_Step__c s : steps){
            List<Deployment_Flow_Step__c> tmp = stepsMap.get(s.Deployment_Flow__c);
            environmentSetIds.add(s.source_environment__c);
            environmentSetIds.add(s.destination_environment__c);
            environmentOrgMap.put(s.source_environment__c, new List<Org__c>());
            environmentOrgMap.put(s.destination_environment__c, new List<Org__c>());
            tmp.add(s);
            stepsMap.put(s.Deployment_Flow__c, tmp);
        }
        for(Org__c o : [select Id, OwnerId, Environment__c, Default_Credential__c from Org__c where Environment__c IN :environmentSetIds]){
            orgMap.put(o.Id, o);
            List<Org__c> tmp = environmentOrgMap.get(o.Environment__c);
            tmp.add(o);
            environmentOrgMap.put(o.Environment__c, tmp);
        }

        //Load Promotions per User Story
        Map<Id,Id> userStoryPromotionMap = new Map<Id,Id>();
        for (Promoted_User_Story__c pus : [SELECT Id, User_Story__c, Promotion__c, Promotion__r.Destination_Environment__c FROM Promoted_User_Story__c WHERE Promotion__c IN :(List<Promotion__c>)records]) {
            userStoryPromotionMap.put(pus.User_Story__c, pus.Promotion__c);
        }
        //Load Environment per User Story
        Map<Id,Id> userStoryEnvironmentMap = new Map<Id,Id>();
        for (User_Story__c us : [SELECT Id, Environment__c FROM User_Story__c WHERE Environment__c IN :destinationEnvironmentsIds]) {
            userStoryEnvironmentMap.put(us.Id, us.Environment__c);
        }

        //Load User Story Metadata from Promotion
        for (User_Story_Metadata__c usMetadata : [SELECT Metadata_API_Name__c, User_Story__c FROM User_Story_Metadata__c WHERE User_Story__c IN :userStoryPromotionMap.keySet()]) {
            if (!promotionMetadatasMap.containsKey(userStoryPromotionMap.get(usMetadata.User_Story__c))) {
                Set<String> metadatas = new Set<String>();
                metadatas.add(usMetadata.Metadata_API_Name__c);
                promotionMetadatasMap.put(userStoryPromotionMap.get(usMetadata.User_Story__c), metadatas);
            }
            else {
                Set<String> metadatas = promotionMetadatasMap.get(userStoryPromotionMap.get(usMetadata.User_Story__c));
                metadatas.add(usMetadata.Metadata_API_Name__c);
                promotionMetadatasMap.put(userStoryPromotionMap.get(usMetadata.User_Story__c), metadatas);
            }
        }

        //Load User Story Metadata from Environment
        for (User_Story_Metadata__c usMetadata : [SELECT Metadata_API_Name__c, User_Story__c, User_Story__r.Environment__c FROM User_Story_Metadata__c WHERE User_Story__r.Environment__c IN :destinationEnvironmentsIds]) {

            if (!environmentsMetadatasMap.containsKey(userStoryEnvironmentMap.get(usMetadata.User_Story__c))) {
                Set<User_Story_Metadata__c> metadatas = new Set<User_Story_Metadata__c>();
                metadatas.add(usMetadata);
                environmentsMetadatasMap.put(userStoryEnvironmentMap.get(usMetadata.User_Story__c), metadatas);
            }
            else {
                Set<User_Story_Metadata__c> metadatas = environmentsMetadatasMap.get(userStoryEnvironmentMap.get(usMetadata.User_Story__c));
                metadatas.add(usMetadata);
                environmentsMetadatasMap.put(userStoryEnvironmentMap.get(usMetadata.User_Story__c), metadatas);
            }
        }
    }
    public static void canPromoteThis(Promotion__c p) {
        Boolean isValidCBMFlow = false;
        Deployment_Flow__c flow;

        if(p.Project__c != null) {
            if(promotionFlows.containsKey(p.Project__c)){
                flow  = promotionFlows.get(p.Project__c).flow;
                isValidCBMFlow = promotionFlows.get(p.Project__c).isCBMFlow;
            } else {
                p.addError(Label.PROMOTION_PROJECT_DEPLOYMENT_FLOW_MISSING);
            }
        } else if(p.Release__c != null) {
            if (releaseProjectsMap.containsKey(p.Release__c) && promotionFlows.containsKey(releaseProjectsMap.get(p.Release__c))) {
                flow  = promotionFlows.get(releaseProjectsMap.get(p.Release__c)).flow;
                isValidCBMFlow = promotionFlows.get(releaseProjectsMap.get(p.Release__c)).isCBMFlow;
            } else {
                p.addError(Label.PROMOTION_RELEASE_DEPLOYMENT_FLOW_MISSING);
            }
        }

        if(flow != null) {
            p.Auto_Resolve_Options__c = flow.Auto_Resolve_Options__c != null ? flow.Auto_Resolve_Options__c : Label.AUTO_RESOLVE_ALL_FILES;
        }

        if(p.Back_Promotion__c && !isValidCBMFlow)p.addError(Label.BACK_PROMOTION_NOT_ENABLED);
        if(LicenseHelper.isCopadoEnabled() || LicenseHelper.isCCMEnabled()) {
            Boolean isActiveFlow = false;
            Boolean isSandboxDestination = false;
            if(p.Project__c != null && promotionFlows.get(p.Project__c) != null) {
            	if(promotionFlows.get(p.Project__c).flow.Active__c)isActiveFlow = true;
        	} else if(p.Release__c != null && promotionFlows.get(releaseProjectsMap.get(p.Release__c)) != null) {
            	if(promotionFlows.get(releaseProjectsMap.get(p.Release__c)).flow.Active__c)isActiveFlow = true;
        	}    
            
            if(isActiveFlow && !LicenseHelper.isCopadoEnabled()) {
                if(p.Destination_Environment__c != null && destinationEnvironmentTypesMap.get(p.Destination_Environment__c) != null) {
            		if(destinationEnvironmentTypesMap.get(p.Destination_Environment__c) == 'Sandbox')isSandboxDestination = true;
        		}      
                
                if(!isValidCBMFLow)p.addError(Label.CBM_FLOW_INVALID);
                if(!isSandboxDestination)p.addError(Label.CCM_DESTINATION_ORG_INVALID);
            } else if(!isActiveFlow)p.addError(Label.PROMOTION_FLOW_INACTIVE);
        } else p.addError(Label.COPADO_DEPLOYER_CCM_LICENSE_NOT_ENABLED);
    }
    public static void validateOrgEnvironmentRelationship(Promotion__c p){
		Org__c sorg = orgMap.get(p.Source_Org_Credential__c);
        Org__c dorg = orgMap.get(p.Destination_Org_Credential__c);
        Id flowId = projectFlowMap.get(p.Project__c);
        if(flowId !=null && p.Source_Environment__c!=null && sorg == null){
            p.addError(Label.FLOW_CREDENTIAL_ERROR);
        }
        if(flowId !=null && p.Destination_Environment__c!=null && dorg == null){
            p.addError(Label.FLOW_CREDENTIAL_ERROR);
        }
        if(sorg!=null && p.Source_Org_Credential__c!=null && sorg.Environment__c!=p.Source_Environment__c){
            p.Source_Org_Credential__c.addError(Label.ORG_CREDENTIAL_NOT_PART_OF_ENVIRONMENT);
        }
        if(dorg!=null && p.Destination_Org_Credential__c!=null && dorg.Environment__c!=p.Destination_Environment__c){
            p.Destination_Org_Credential__c.addError(Label.ORG_CREDENTIAL_NOT_PART_OF_ENVIRONMENT);
        }
    }
    public static void setSourceOrgFromEnvironment(Promotion__c promotion){
        if(!promotion.Back_Promotion__c) {
            if(promotion.Source_Org_Credential__c == null && promotion.Source_Environment__c != null){
                for(Org__c org : environmentOrgMap.get(promotion.Source_Environment__c)){
                    if(org.Default_Credential__c){
                        promotion.Source_Org_Credential__c = org.Id;
                        break;
                    }
                    if(org.OwnerId == promotion.OwnerId && promotion.Source_Org_Credential__c==null)promotion.Source_Org_Credential__c = org.Id;
                }
            }
        } else {
            if(promotion.Destination_Org_Credential__c == null && promotion.Destination_Environment__c != null){
                for(Org__c org : environmentOrgMap.get(promotion.Destination_Environment__c)){
                    if(org.Default_Credential__c){
                        promotion.Destination_Org_Credential__c = org.Id;
                        break;
                    }
                    if(org.OwnerId == promotion.OwnerId && promotion.Destination_Org_Credential__c == null)promotion.Destination_Org_Credential__c = org.Id;
                }
            }
        }
        
        if(!promotion.Back_Promotion__c && promotion.Source_Org_Credential__c == null && promotion.Source_Environment__c != null) {
            promotion.addError(Label.ERROR_PROMOTION_SOURCE_ORG_NOT_FOUND);
        } else if(promotion.Back_Promotion__c && promotion.Destination_Org_Credential__c == null && promotion.Destination_Environment__c != null) {
            promotion.addError(Label.ERROR_PROMOTION_SOURCE_ORG_NOT_FOUND);
        }
    }
    public static Boolean hasEqualDeploymentFlows(Promotion__c promotion) {
        Id flowId = projectFlowMap.get(promotion.Project__c);
        if (promotion.Release__c != null) {
            List<Release__c> releases = [SELECT Project__c FROM Release__c WHERE Id = :promotion.Release__c];
            for (Release__c release : releases) {
                Id releaseFlowId = projectFlowMap.get(release.Project__c);
                if(flowId != null && releaseFlowId != null && flowId != releaseFlowId) {
                    // TODO: Change this error message to a custom label
                    promotion.addError('When both a project and a release are specified in a user story, the deployment flow linked to the project must be the same deployment flow linked to the release project.');
                    return false;
                }
            }
        }
        return true;
    }
    public static void setDestinationOrgFromFlow(Promotion__c promotion){
        Environment__c stepSourceEnvironment = null;
        Environment__c stepDestinationEnvironment = null;
        Org__c stepSourceOrg = null;
        Org__c stepDestinationOrg = null;

        Id flowId = projectFlowMap.get(promotion.Project__c);
        if (promotion.Release__c != null) {
            List<Release__c> releases = [SELECT Project__c FROM Release__c WHERE Id = :promotion.Release__c];
            for (Release__c release : releases) {
                if(projectFlowMap.get(release.Project__c) != null) {
                    flowId = projectFlowMap.get(release.Project__c);
                }
            }
        }
        
        List<Deployment_Flow_Step__c> tmp = stepsMap.get(flowId);
        if(tmp != null){
            system.debug('### we have steps...');
            for(Deployment_Flow_Step__c step : tmp){
                system.debug('### Iterating steps.... ');

                if(!promotion.Back_Promotion__c && promotion.Source_Environment__c != null) {
                    System.debug('## BackPromotion = false');
                    if(step.Source_Environment__c == promotion.Source_Environment__c){
                        promotion.Destination_Environment__c = step.Destination_Environment__c;
                        System.debug('## Promotion Source Environment: '+promotion.Destination_Environment__c);
                        destinationEnvironmentTypesMap.put(promotion.Destination_environment__c, step.Destination_Environment__r.Type__c);
                        for(Org__c org : environmentOrgMap.get(promotion.Destination_Environment__c)){
                            if(org.Default_Credential__c){
                                promotion.Destination_Org_Credential__c = org.Id;
                                break;
                            }
                            if(org.OwnerId == promotion.OwnerId && promotion.Destination_Org_Credential__c == null)promotion.Destination_Org_credential__c = org.Id;
                        }
                        System.debug('## promotion.Destination_Org_Credential__c: '+promotion.Destination_Org_Credential__c);
                        break;
                    }
                } else if(promotion.Back_Promotion__c && promotion.Destination_Environment__c != null) {
                    System.debug('## BackPromotion = true');
                    if(step.Source_Environment__c == promotion.Destination_Environment__c){
                        promotion.Source_Environment__c = step.Destination_Environment__c;
                        System.debug('## Promotion Source Environment: '+promotion.Source_Environment__c);
                        destinationEnvironmentTypesMap.put(promotion.Destination_Environment__c, step.Source_Environment__r.Type__c);
                        for(Org__c org : environmentOrgMap.get(promotion.Source_Environment__c)){
                            if(org.Default_Credential__c){
                                promotion.Source_Org_Credential__c = org.Id;
                                break;
                            }
                            if(org.OwnerId == promotion.OwnerId && promotion.Source_Org_Credential__c == null)promotion.Source_Org_Credential__c = org.Id;
                            System.debug('## promotion.Source_Org_Credential__c: '+promotion.Source_Org_Credential__c);
                        }
                        break;
                    }
                    System.debug('## EXIT BackPromotion = true');
                }
            }
        }
        
        if (!promotion.Back_Promotion__c && promotion.Destination_Org_Credential__c == null && promotion.Destination_Environment__c != null) {
            promotion.addError(Label.ERROR_PROMOTION_DESTINATION_ORG_NOT_FOUND);
        } else if(promotion.Back_Promotion__c && promotion.Source_Org_Credential__c == null && promotion.Source_Environment__c != null) {
            promotion.addError(Label.ERROR_PROMOTION_DESTINATION_ORG_NOT_FOUND);
        }
    }
    
    public static void accumulateIfCompleted(Promotion__c pNew, Promotion__c pOld) {
        if(pOld.Status__c!='Completed' || pNew.Status__c=='Completed')
            completedPromotions.add(pNew);
    }
    public static void runSeleniumTestGroups() {
        RunTestGroupsBatch.runSeleniumTestsOfPromotions(RunTestGroupsBatch.ENV_DEST, RunTestGroupsBatch.MODE_ALL_TESTS, completedPromotions);
    }

    public static void markUserStoryMetadataBackPromoted(Promotion__c promo) {

        /**
         * If we find a coincidence between the User Story Metadata in a Completed - Back Promotion
         * we mark User Story Metadata of Destination Environment as Back Promoted
         */
        if (environmentIndexBackPromotionMap.containsKey(promo.Destination_Environment__c)) {
            if (environmentIndexBackPromotionMap.get(promo.Destination_Environment__c) && promo.Status__c == 'Completed' && promo.Back_Promotion__c) {
                if (promotionMetadatasMap.containsKey(promo.Id) && environmentsMetadatasMap.containsKey(promo.Destination_Environment__c)) {
                    Set<String> promoMetadatas = promotionMetadatasMap.get(promo.Id);
                    for (User_Story_Metadata__c usm : environmentsMetadatasMap.get(promo.Destination_Environment__c)) {
                        if (promoMetadatas.contains(usm.Metadata_API_Name__c)) {
                            usm.Status__c = Label.BACK_PROMOTED;
                            usMetadataUpd.add(usm);
                        }
                    }
                }
            }
        }
    }

    public static void updateUserStoryMetadatasBackPromoted() {
        if(usMetadataUpd != null) {
            update usMetadataUpd;
        }
    }
}