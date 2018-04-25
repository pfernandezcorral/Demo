/**
 * GlobalUtilities class without sharing.
 *
 **/
public without sharing class GlobalUtilities {

    public class deploymentFlowDetails {
        public Boolean isCBMFlow {get; set;}
        public Deployment_Flow__c flow {get; set;}
        public deploymentFlowDetails() {
            this.isCBMFlow = false;
            this.flow = null;
        }
    }

    public static User_Story__c getUserStoryById(string recordId) {
        SObject so = GlobalUtilities.queryAllfieldsWithoutSharing('User_Story__c', recordId, 'Org_Credential__r.Org_Type__c');
        if (so == null)return null;
        User_Story__c o = (User_Story__c) so;
        return o;
    }

    public static deploymentFlowDetails getDeploymentFlowDetails(String recordId, String otherFields) {
        deploymentFlowDetails details = new deploymentFlowDetails();
        System.debug('# recordId: ' + recordId);
        System.debug('# otherFields: ' + otherFields);
        details.flow = (Deployment_Flow__c)queryAllFieldsWithoutSharing('Deployment_Flow__c', recordId, otherFields);
        details.isCBMFlow = (details.flow.Git_Repository__c != null && details.flow.Main_Branch__c != null);
        return details;
    }
    public static deploymentFlowDetails getUserStoryDeploymentFlowDetails(String userStoryId, String otherFields) {
        Id deploymentFlowId = null;
        User_Story__c us = [SELECT Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c FROM User_Story__c WHERE Id = :userStoryId];
        if (us.Project__r.Deployment_Flow__c != null) {
            deploymentFlowId = us.Project__r.Deployment_Flow__c;
        } else if (us.Release__r.Project__r.Deployment_Flow__c != null) {
            deploymentFlowId = us.Release__r.Project__r.Deployment_Flow__c;
        }

        if (deploymentFlowId != null) {
            return getDeploymentFlowDetails(deploymentFlowId, otherFields);
        }

        return new deploymentFlowDetails();
    }
    public static List<User_Story__c> getUserStoriesAhead(String flowId, List<Deployment_Flow_Step__c> flowSteps) {
        List<User_Story__c> userStoriesAhead = new List<User_Story__c>();
        Set<String> sourceEnvironmentIds = new Set<String>();
        for (Deployment_Flow_Step__c dfs : flowSteps) {
            sourceEnvironmentIds.add(dfs.Source_Environment__c);
        }
        Map<String, String> d = getAllFieldsWithoutSharing('User_Story__c');
        String soqlString = 'SELECT ' + d.get(Label.FIELDS) + ' ,Project__r.Name, Release__r.Name, Org_Credential__r.Org_Type__c FROM ' + d.get(Label.OBJECT) + ' WHERE Exclude_From_CBM__c = FALSE AND Status__c != \'Cancelled\' AND (Project__r.Deployment_Flow__c = \'' + flowId + '\' OR Release__r.Project__r.Deployment_Flow__c = \'' + flowId + '\') AND Environment__c IN:sourceEnvironmentIds ORDER BY Name DESC';
        userStoriesAhead = Database.query(soqlString);
        System.debug(loggingLevel.Error, '*** userStoriesAhead: ' + userStoriesAhead);
        return userStoriesAhead;
    }
    public static List<User_Story__c> getUserStoriesAhead(Deployment_Flow_Step__c flowStep) {
        List<User_Story__c> userStoriesAhead = new List<User_Story__c>();
        Map<String, String> d = getAllFieldsWithoutSharing('User_Story__c');
        String soqlString = 'SELECT ' + d.get(Label.FIELDS) + ' ,Project__r.Name, Release__r.Name, Org_Credential__r.Org_Type__c FROM ' + d.get(Label.OBJECT) + ' WHERE Exclude_From_CBM__c = FALSE AND Status__c != \'Cancelled\' AND (Project__r.Deployment_Flow__c = \'' + flowStep.Deployment_Flow__c + '\' OR Release__r.Project__r.Deployment_Flow__c = \'' + flowStep.Deployment_Flow__c + '\') AND Environment__c = \'' + flowStep.Source_Environment__c + '\' AND Promote_Change__c = TRUE ORDER BY Name DESC Limit 999';
        userStoriesAhead = Database.query(soqlString);
        System.debug('### userStoriesAhead: ' + userStoriesAhead);
        System.debug('### count: ' + userStoriesAhead.size());

        return userStoriesAhead;
    }
    public static Map<Id, Set<String>> rebasePromotedUserStoryDestinations = new Map<Id, Set<String>>();
    public static Map<Id, List<User_Story__c>> getRebaseUserStories(Id flowId, List<Deployment_Flow_Step__c> flowSteps, String destinationStepSourceEnv) {
        System.debug(loggingLevel.Error, '*** destinationStepSourceEnv: ' + destinationStepSourceEnv);
        Map<Id, List<User_Story__c>> userStoriesBehind = new Map<Id, List<User_Story__c>>();
        Map<Id, List<String>> busIds = new Map<Id, List<String>>();

        Set<Id> usIds = new Set<Id>();
        Set<Id> pusIds = new Set<Id>();
        Map<Id, Set<Id>> usSourceMap = new Map<Id, Set<Id>>();
        Set<Id> sourceAndDestination = new Set<Id>();
        Set<Id> sourceEnvs = new Set<Id>();
        for (Deployment_Flow_Step__c fs : flowSteps) {
            sourceAndDestination.add(fs.Source_Environment__c);
            sourceAndDestination.add(fs.Destination_Environment__c);
            sourceEnvs.add(fs.Source_Environment__c);
        }

        for (Promoted_User_Story__c pus : [SELECT Id, Name, User_Story__c , Promotion__r.Source_Environment__c, Promotion__r.Destination_Environment__c, Promotion__r.Back_Promotion__c
                                           FROM Promoted_User_Story__c
                                           WHERE User_Story__r.Exclude_From_CBM__c = FALSE AND (User_Story__r.Project__r.Deployment_Flow__c = : flowId OR
                                                   User_Story__r.Release__r.Project__r.Deployment_Flow__c = : flowId) AND
                                                   Promotion__r.Status__c = 'Completed' AND User_Story__r.Status__c != 'Cancelled' AND
                                                           Promotion__r.Source_Environment__c IN: sourceAndDestination]) {
            pusIds.add(pus.Id);
            if (rebasePromotedUserStoryDestinations.containsKey(pus.User_Story__c)) {
                Set<String> temp = rebasePromotedUserStoryDestinations.get(pus.User_Story__c);
                if(pus.Promotion__r.Destination_Environment__c == destinationStepSourceEnv){
                    temp.add(pus.Promotion__r.Source_Environment__c);
                }
                temp.add(pus.Promotion__r.Destination_Environment__c);
                rebasePromotedUserStoryDestinations.put(pus.User_Story__c, temp);
            } else {
                Set<String> temp = new Set<String>();
                if(pus.Promotion__r.Destination_Environment__c == destinationStepSourceEnv){
                    temp.add(pus.Promotion__r.Source_Environment__c);
                }
                temp.add(pus.Promotion__r.Destination_Environment__c);
                rebasePromotedUserStoryDestinations.put(pus.User_Story__c, temp);
            }
            System.debug(loggingLevel.Error, '*** pus.Promotion__r.Destination_Environment__c: ' + pus.Promotion__r.Destination_Environment__c);
            System.debug(loggingLevel.Error, '*** destinationStepSourceEnv: ' + destinationStepSourceEnv);
            System.debug(loggingLevel.Error, '*** pus.Promotion__r.Source_Environment__c: ' + pus.Promotion__r.Source_Environment__c);
            if (pus.Promotion__r.Destination_Environment__c == destinationStepSourceEnv ||
                    pus.Promotion__r.Source_Environment__c == destinationStepSourceEnv) {
                if (busIds.containsKey(pus.Promotion__r.Source_Environment__c)) {
                    List<String> temp = busIds.get(pus.Promotion__r.Source_Environment__c);
                    temp.add(pus.User_Story__c);
                    usIds.add(pus.User_Story__c);
                } else {
                    List<String> temp = new List<String>();
                    temp.add(pus.User_Story__c);
                    usIds.add(pus.User_Story__c);
                }

                if (!usSourceMap.containsKey(pus.User_Story__c)) {
                    Set<Id> tempEnvIds = new Set<Id>();
                    if (pus.Promotion__r.Destination_Environment__c == destinationStepSourceEnv) {
                        tempEnvIds.add(pus.Promotion__r.Source_Environment__c);
                    } else if (pus.Promotion__r.Source_Environment__c == destinationStepSourceEnv) {
                        tempEnvIds.add(pus.Promotion__r.Destination_Environment__c);
                    }

                    usSourceMap.put(pus.User_Story__c, tempEnvIds);
                } else {
                    Set<Id> tempEnvIds = usSourceMap.get(pus.User_Story__c);
                    if (pus.Promotion__r.Destination_Environment__c == destinationStepSourceEnv) {
                        tempEnvIds.add(pus.Promotion__r.Source_Environment__c);
                    } else if (pus.Promotion__r.Source_Environment__c == destinationStepSourceEnv) {
                        tempEnvIds.add(pus.Promotion__r.Destination_Environment__c);
                    }
                    usSourceMap.put(pus.User_Story__c, tempEnvIds);
                }
            }
        }
        System.debug(loggingLevel.Error, '*** rebasePromotedUserStoryDestinations: ' + rebasePromotedUserStoryDestinations);
        System.debug(loggingLevel.Error, '*** usIds: ' + usIds);
        Map<String, String> d = getAllFieldsWithoutSharing('User_Story__c');
        System.debug(loggingLevel.Error, '*** usSourceMap: ' + usSourceMap);
        String commitsSoql = 'SELECT Id FROM User_Story_Commits__r';
        String externalCIJobsSoql = 'SELECT Id FROM External_CI_Jobs__r';
        String deploymentTasksSoql = 'SELECT Id FROM Deployment_Tasks__r';
        String soqlString = 'SELECT ' + d.get(Label.FIELDS) + ' ,Project__r.Name,Release__r.Name,Org_Credential__r.Org_Type__c,(' + commitsSoql + '),(' + externalCIJobsSoql + '),(' + deploymentTasksSoql + ') FROM ' + d.get(Label.OBJECT) + ' WHERE Exclude_From_CBM__c = FALSE AND (Id IN :usIds OR (Environment__c =:destinationStepSourceEnv AND Id NOT IN:usIds))';
        System.debug(loggingLevel.Error, '*** soqlString: ' + soqlString);
        List<User_Story__c> temp = Database.query(soqlString);
        System.debug(loggingLevel.Error, '*** temp: ' + temp);
        for (User_Story__c us : temp) {
            if (usSourceMap.containsKey(us.Id) && !usSourceMap.get(us.Id).containsAll(sourceEnvs) && (us.User_Story_Commits__r.size() > 0 || us.External_CI_Jobs__r.size() > 0 || us.Deployment_Tasks__r.size() > 0)) {
                for (Id sourceEnv : usSourceMap.get(us.Id)) {
                    if (userStoriesBehind.containsKey(sourceEnv)) {
                        List<User_Story__c> tempUS = userStoriesBehind.get(sourceEnv);
                        tempUS.add(us);
                        userStoriesBehind.put(sourceEnv, tempUS);
                    } else {
                        List<User_Story__c> tempUS = new List<User_Story__c>();
                        tempUS.add(us);
                        userStoriesBehind.put(sourceEnv, tempUS);
                    }
                }
            } else if (!usSourceMap.containsKey(us.Id) && us.Environment__c == destinationStepSourceEnv) {
                List<User_Story__c> tempUS = new List<User_Story__c>();
                tempUS.add(us);
                userStoriesBehind.put(destinationStepSourceEnv, tempUS);
            }
        }

        return userStoriesBehind;
    }
    public static List<User_Story__c> getUserStoriesBehind(Deployment_Flow_Step__c flowStep) {
        List<User_Story__c> userStoriesBehind = new List<User_Story__c>();
        // If last pull sync date is bigger than last merge base than use last sync date
        /*Datetime lastTransactionDate = flowStep.Last_Merge_Base__c;
        if (flowStep.Last_Pull_CBM_Sync__c > flowStep.Last_Merge_Base__c) {
            lastTransactionDate = flowStep.Last_Pull_CBM_Sync__c;
        }*/
        Set<String> usIds = new Set<String>();
        Set<String> busIds = new Set<String>();
        // Getting all promoted user stories that are modified after the lastTransaction date, not excluded from CBM and part of the current flows requested step.
        // In addition to above explanation
        // Promotion has to be completed in order to consider the user story has ben stream lined to the next environment
        // User story should not be cancelled. Cancelled USs are ignored since they should not be promoteable.
        // Promotions destination env has be equal to flowSteps destination env. This is necessary to consider user stories current environment.

        Set<Id> sourceAndDestination = new Set<Id> {flowStep.Source_Environment__c, flowStep.Destination_Environment__c};
        //System.debug('lastTransactionDate = ' + lastTransactionDate);
        for (Promoted_User_Story__c pus : [SELECT Id, Name, User_Story__c , Promotion__r.Source_Environment__c, Promotion__r.Destination_Environment__c, Promotion__r.Back_Promotion__c
                                           FROM Promoted_User_Story__c
                                           WHERE
                                           User_Story__r.Exclude_From_CBM__c = FALSE AND
                                                   (User_Story__r.Project__r.Deployment_Flow__c = :flowStep.Deployment_Flow__c OR User_Story__r.Release__r.Project__r.Deployment_Flow__c = :flowStep.Deployment_Flow__c) AND
                                                   Promotion__r.Status__c = 'Completed' AND User_Story__r.Status__c != 'Cancelled' AND
                                                           (Promotion__r.Destination_Environment__c in :sourceAndDestination OR
                                                                   Promotion__r.Source_Environment__c in :sourceAndDestination)
                                                           ORDER BY Promotion__r.Back_Promotion__c DESC
                                          ]) {
            System.debug('*** promoted story: ' + pus.Name);
            if (pus.Promotion__r.Destination_Environment__c == flowStep.Source_Environment__c ||
                    pus.Promotion__r.Source_Environment__c == flowStep.Source_Environment__c) {
                busIds.add(pus.User_Story__c);
            }
            if (pus.Promotion__r.Destination_Environment__c == flowStep.Destination_Environment__c ||
                    pus.Promotion__r.Source_Environment__c == flowStep.Destination_Environment__c) {
                usIds.add(pus.User_Story__c);
            }
        }
        Map<String, String> d = getAllFieldsWithoutSharing('User_Story__c');
        System.debug(loggingLevel.Error, '*** busIds: ' + busIds);
        System.debug(loggingLevel.Error, '*** usIds: ' + usIds);
        String commitsSoql = 'SELECT Id,Snapshot_Commit__c,Snapshot_Commit__r.Org__c FROM User_Story_Commits__r';
        String externalCIJobsSoql = 'SELECT Id FROM External_CI_Jobs__r';
        String deploymentTasksSoql = 'SELECT Id FROM Deployment_Tasks__r';
        String soqlString = 'SELECT ' + d.get(Label.FIELDS) + ' ,Project__r.Name,Release__r.Name,Org_Credential__r.Org_Type__c,(' + commitsSoql + '),(' + externalCIJobsSoql + '),(' + deploymentTasksSoql + ') FROM ' + d.get(Label.OBJECT) + ' WHERE (Exclude_From_CBM__c = false AND Id IN :usIds AND Id NOT IN: busIds) OR (Exclude_From_CBM__c = false AND Environment__c =\'' + flowStep.Destination_Environment__c + '\' AND Id NOT IN: busIds AND Status__c != \'Cancelled\') Limit 999';
        List<User_Story__c> temp = Database.query(soqlString);
        System.debug('*** query us behind: ' + soqlString);
        for (User_Story__c us : temp) {
            if(us.User_Story_Commits__r.size() > 0 || us.External_CI_Jobs__r.size() > 0 || us.Deployment_Tasks__r.size() > 0){
                userStoriesBehind.add(us);
                System.debug('add us behind: ' + us.Name);
            } else {
                // skip the us since there is no commit or no external CI or deployment task associated with the US
                System.debug('ignore us behind (nothing to promote): ' + us.Name);
            }
        }
        System.debug('userStoriesBehind: ' + userStoriesBehind);
        System.debug('count: ' + userStoriesBehind.size());

        return userStoriesBehind;
    }

    public static SObject queryAllfieldsWithoutSharing(String sObjectName, String recordId, String otherFields) {
        recordId = EncodingUtil.urlEncode(recordId, 'UTF-8');
        Map<String, String> d = getAllFieldsWithoutSharing(sObjectName);
        String queryString = 'SELECT ' + d.get(Label.FIELDS) + ' FROM ' + d.get(Label.OBJECT) + ' WHERE ID =:recordId';
        if (otherFields != '') {
            queryString = 'SELECT ' + d.get(Label.FIELDS) + ', ' + otherFields + ' FROM ' + d.get(Label.OBJECT) + ' WHERE ID =:recordId';
        }
        System.debug('QUERY: ' + queryString);
        List<SObject> sos = Database.query(queryString);
        if (sos.size() > 0) {
            return sos.get(0);
        }
        return null;
    }
    public static Map<String, String> getAllFieldsWithoutSharing(String sObjectName) {
        //Ignore the PermissionSet object for the PermissionSet Explorer
        if (sObjectName != Label.PERMISSION_SET_SOBJECT_NAME) {
            sObjectName = Settings.ns + sObjectName;
        }
        Map<String, String> result = new Map<String, String>();
        if (!Schema.getGlobalDescribe().containsKey(sObjectName)) {
            System.debug('INVALID OBJECT ' + sObjectName);
            return null;
        }
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().SObjectType.getDescribe().fields.getMap();

        List<String> accessiblefields = new List<String>();

        for (Schema.SObjectField field : fields.values()) {
            accessiblefields.add(field.getDescribe().getName());
        }

        String allfields = '';

        for (String fieldname : accessiblefields) {
            allfields += fieldname + ',';
        }

        allfields = allfields.subString(0, allfields.length() - 1);

        result.put(Label.OBJECT, sObjectName);
        result.put(Label.FIELDS, allfields);
        return result;
    }
    public static List<User_Story__c> getUserStoriesFromFieldsetBehind(Set<String> fieldNamesSet,Deployment_Flow_Step__c flowStep) {
        List<User_Story__c> userStoriesBehind = new List<User_Story__c>();
        // If last pull sync date is bigger than last merge base than use last sync date
        /*Datetime lastTransactionDate = flowStep.Last_Merge_Base__c;
        if (flowStep.Last_Pull_CBM_Sync__c > flowStep.Last_Merge_Base__c) {
            lastTransactionDate = flowStep.Last_Pull_CBM_Sync__c;
        }*/
        Set<String> usIds = new Set<String>();
        Set<String> busIds = new Set<String>();
        // Getting all promoted user stories that are modified after the lastTransaction date, not excluded from CBM and part of the current flows requested step.
        // In addition to above explanation
        // Promotion has to be completed in order to consider the user story has ben stream lined to the next environment
        // User story should not be cancelled. Cancelled USs are ignored since they should not be promoteable.
        // Promotions destination env has be equal to flowSteps destination env. This is necessary to consider user stories current environment.

        Set<Id> sourceAndDestination = new Set<Id> {flowStep.Source_Environment__c, flowStep.Destination_Environment__c};
        //System.debug('lastTransactionDate = ' + lastTransactionDate);
        for (Promoted_User_Story__c pus : [SELECT Id, Name, User_Story__c , Promotion__r.Source_Environment__c, Promotion__r.Destination_Environment__c, Promotion__r.Back_Promotion__c
                                           FROM Promoted_User_Story__c
                                           WHERE //Promotion__r.Last_Merge_Base__codifiedDate > :lastTransactionDate AND
                                                    User_Story__r.Exclude_From_CBM__c = FALSE AND
                                                    (User_Story__r.Project__r.Deployment_Flow__c = :flowStep.Deployment_Flow__c OR User_Story__r.Release__r.Project__r.Deployment_Flow__c = :flowStep.Deployment_Flow__c) AND
                                                    Promotion__r.Status__c = 'Completed' AND User_Story__r.Status__c != 'Cancelled' AND
                                                    (Promotion__r.Destination_Environment__c in :sourceAndDestination OR
                                                    Promotion__r.Source_Environment__c in :sourceAndDestination)
                                                    ORDER BY Promotion__r.Back_Promotion__c DESC
                                                    ]) {
            System.debug('*** promoted story: ' + pus.Name);
            if (pus.Promotion__r.Destination_Environment__c == flowStep.Source_Environment__c ||
                    pus.Promotion__r.Source_Environment__c == flowStep.Source_Environment__c) {
                busIds.add(pus.User_Story__c);
            }
            if (pus.Promotion__r.Destination_Environment__c == flowStep.Destination_Environment__c ||
                    pus.Promotion__r.Source_Environment__c == flowStep.Destination_Environment__c) {
                usIds.add(pus.User_Story__c);
            }
        }
        Map<String, String> d = getAllFieldsFromFieldsetWithoutSharing(fieldNamesSet,'User_Story__c');
        System.debug(loggingLevel.Error, '*** busIds: ' + busIds);
        System.debug(loggingLevel.Error, '*** usIds: ' + usIds);
        String commitsSoql = 'SELECT Id FROM User_Story_Commits__r';
        String externalCIJobsSoql = 'SELECT Id FROM External_CI_Jobs__r';
        String deploymentTasksSoql = 'SELECT Id FROM Deployment_Tasks__r';
        String soqlString = 'SELECT ' + d.get(Label.FIELDS) + ' ,Project__r.Name,Release__r.Name,Org_Credential__r.Org_Type__c,(' + commitsSoql + '),(' + externalCIJobsSoql + '),(' + deploymentTasksSoql + ') FROM ' + d.get(Label.OBJECT) + ' WHERE (Exclude_From_CBM__c = false AND Id IN :usIds AND Id NOT IN: busIds) OR (Exclude_From_CBM__c = false AND Environment__c =\'' + flowStep.Destination_Environment__c + '\' AND Id NOT IN: busIds) Limit 999';//
        List<User_Story__c> temp = Database.query(soqlString);
        System.debug('*** query us behind: ' + soqlString);
        for (User_Story__c us : temp) {
            if(us.User_Story_Commits__r.size() > 0 || us.External_CI_Jobs__r.size() > 0 || us.Deployment_Tasks__r.size() > 0){
                userStoriesBehind.add(us);
                System.debug('add us behind: ' + us.Name);
            } else {
                // skip the us since there is no commit or no external CI or deployment task associated with the US
                System.debug('ignore us behind (nothing to promote): ' + us.Name);
            }
        }
        System.debug('userStoriesBehind: ' + userStoriesBehind);
        System.debug('count: ' + userStoriesBehind.size());

        return userStoriesBehind;
    }
    public static List<User_Story__c> getUserStoriesFromFieldsetAhead(Set<String> fieldNamesSet,Deployment_Flow_Step__c flowStep) {
        List<User_Story__c> userStoriesAhead = new List<User_Story__c>();
        Map<String, String> d = getAllFieldsFromFieldsetWithoutSharing(fieldNamesSet,'User_Story__c');
        String soqlString = 'SELECT ' + d.get(Label.FIELDS) + ' ,Project__r.Name, Release__r.Name,Org_Credential__r.Org_Type__c FROM ' + d.get(Label.OBJECT) + ' WHERE Exclude_From_CBM__c = FALSE AND Status__c != \'Cancelled\' AND (Project__r.Deployment_Flow__c = \'' + flowStep.Deployment_Flow__c + '\' OR Release__r.Project__r.Deployment_Flow__c = \'' + flowStep.Deployment_Flow__c + '\') AND Environment__c = \'' + flowStep.Source_Environment__c + '\' AND Promote_Change__c = TRUE ORDER BY Name DESC Limit 999';
        System.debug('### soqlString: ' + soqlString);
        userStoriesAhead = Database.query(soqlString);
        System.debug('### userStoriesAhead: ' + userStoriesAhead);
        System.debug('### count: ' + userStoriesAhead.size());

        return userStoriesAhead;
    }
    public static Map<String, String> getAllFieldsFromFieldsetWithoutSharing(Set<String> fieldNamesSet,String sObjectName) {
        //Ignore the PermissionSet object for the PermissionSet Explorer
        if (sObjectName != Label.PERMISSION_SET_SOBJECT_NAME) {
            sObjectName = Settings.ns + sObjectName;
        }
        Map<String, String> result = new Map<String, String>();
        if (!Schema.getGlobalDescribe().containsKey(sObjectName)) {
            System.debug('INVALID OBJECT ' + sObjectName);
            return null;
        }
        Schema.DescribeSObjectResult dsr = Schema.getGlobalDescribe().get(sObjectName).getDescribe();

        Map<String, Schema.SObjectField> fieldMap = dsr.fields.getMap();

        String allfields = '';

        for(String key : fieldMap.keySet()){
            for(String fieldName : fieldNamesSet){
                if(fieldName == key){
                    allfields += fieldName + ',';
                }
            }
        }

        allfields = allfields.subString(0, allfields.length() - 1);

        result.put(Label.OBJECT, sObjectName);
        result.put(Label.FIELDS, allfields);
        return result;
    }
    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String ObjectName)
    {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();

        //system.debug('====>' + DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName));

        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);

        //List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
        //system.debug('fieldSetMemberList ====>' + fieldSetMemberList);
        return fieldSetObj.getFields();
    }

    /*
        Method to retrieve all the possible dependencies for the user stories given

     */

    public static list<User_Story__c> getUserStoriesDependencies(set<Id> usIds, Id envId) {
        //get Custom metadata to ignore Team Dependencies depending of defined Value
        String skipAPI = 'Skip_Dependency__c';
        Copado_Setting__mdt cs = [SELECT Id, Text_Field__c  FROM Copado_Setting__mdt WHERE DeveloperName = 'Team_Dependency' LIMIT 1];
        if (cs.Text_Field__c != null && cs.Text_Field__c != skipAPI) {
            skipAPI = cs.Text_Field__c;
        }

        //User Story to return
        list<User_Story__c> usToReturn = new list<User_Story__c>();


        String query = '';
        //We get the universe of user stories with their relevant information (Dependencies )
        query = 'SELECT Id, Environment__c, Name, User_Story_Title__c, Status__c, Environment__r.Name, ' +
                '(select Id, Name, Deliverable__c, Dependency_Status__c, Dependent_Team__c, Dependent_Team__r.Name from Team_Dependencies_On_UStory__r where Dependent_User_Story__c in: usIds), ' +
                '(select Id, Promotion__c, User_Story__c, Promotion__r.Destination_Environment__c, Promotion__r.Source_Environment__c from Promoted_User_Stories__r where Promotion__r.Status__c = \'Completed\') ' +
                'FROM   User_Story__c ' +
                'WHERE Id NOT IN : usIds ' +
                'AND Id IN (select Provider_User_Story__c from Team_Dependency__c where Dependent_User_Story__c  in: usIds AND ' + skipAPI + ' = FALSE)';

        system.debug(query);
        try {
            list<User_Story__c> usUniverse = Database.query(query);
            system.debug(usUniverse);
            for (User_Story__c us : usUniverse) {
                Boolean skipUS = false;
                if (us.Promoted_User_Stories__r.size() > 0) {
                    //Iterate over all completed promoted user stories to see in which environments it has been if it has been all environments
                    //of all user stories to be promoted then the environments should cotain the dependencies already
                    for (Promoted_User_Story__c pus : us.Promoted_User_Stories__r) {
                        if (pus.Promotion__r.Destination_Environment__c == envId || pus.Promotion__r.Source_Environment__c == envId) {
                            skipUS = true;
                            break;
                        }
                    }
                }
                if (!skipUS) {
                    usToReturn.add(us);
                }
            }
            system.debug(usToReturn);
        } catch (exception e) {
            //there was an issue, normally Dependency Skip API Name was set wrong
            system.debug(e.getMessage());
        }
        return usToReturn;
    }

    /*
      jgaviria@copa.do
      Get latest Compliance Scan Result and Finding to related record
      */
    public static Compliance_Scan_Result__c getWOSharingCSR(Id pId, String apiRelName) {
        Compliance_Scan_Result__c csr = new Compliance_Scan_Result__c();
        try {
            if (String.isNotBlank(pId) && String.isNotBlank(apiRelName)) {
                String query = 'SELECT Id, Status__c, ' + apiRelName +
                               ', (select Id, Severity__c, Compliance_Rule__r.Action__c from Compliance_Findings__r where Compliance_Rule__r.Action__c != \'Document Only\' order by  Compliance_Rule__r.Action__c, Severity__c limit 1) ' +
                               'FROM  Compliance_Scan_Result__c ' +
                               'WHERE ' + apiRelName + ' =: pId' +
                               ' ORDER BY CreatedDate DESC ' +
                               'LIMIT 1';
                System.debug(loggingLevel.Error, '*** query: ' + query);
                List<Compliance_Scan_Result__c> csrL = Database.query(query);
                System.debug(loggingLevel.Error, '*** csrL: ' + csrL);

                if (csrL.size() > 0) {
                    System.debug(loggingLevel.Error, '*** csrL: ' + csrL[0].Compliance_Findings__r);
                    csr = csrL[0];
                }
            }
        } catch (exception e) {
            //Return empty Object Component will validate
            system.debug('There is no FLS or query is not succesfull ' + e.getMessage());
        }
        return csr;
    }

    /**
     * Method to update the User Story Base Branch field.
     */
    public static void updateUserStoryBaseBranch(Id userStoryId, String baseBranch) {
        if(!String.isBlank(baseBranch)) {
            User_Story__c userStory;
            for (User_Story__c us : [SELECT Id, Base_Branch__c FROM User_Story__c WHERE Id = :userStoryId LIMIT 1]) {
                userStory = us;
            }

            if(userStory != null) {
                userStory.Base_Branch__c = baseBranch;
                update userStory;
            }
        }
    }

}