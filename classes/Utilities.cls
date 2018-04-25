public with sharing class Utilities {

    public static void resetStatuses(String dId, boolean allJobs) {
        Step__c[] steps = [select Id, Status__c, Deployment__c from Step__c where Deployment__c = :EncodingUtil.urlEncode(dId, 'UTF-8') order by order__c, createddate limit 10000];
        Deployment_Job__c[] jobs = [select Id, Status__c, Step__r.Deployment__c, Deployed__c from Deployment_Job__c where Step__r.Deployment__c = :EncodingUtil.urlEncode(dId, 'UTF-8') limit 10000];
        Destination_Org__c [] dos = [select Id, Status__c, Deployment__c from Destination_Org__c where Deployment__c = :EncodingUtil.urlEncode(dId, 'UTF-8') limit 10000];
        Integer i = 0;
        for (Step__c s : steps) {
            s.Status__c  = 'Not started';
            i++;
            s.order__c = i;
        }
        for (Destination_Org__c d : dos) { d.Status__c  = 'Not started'; }
        for (Deployment_Job__c o : jobs) {
            if (allJobs || o.Status__c != 'Success') {
                o.Status__c = 'Pending';
                if (allJobs)o.Early_Completion_Status__c = 'Pending';
                o.Deployed__c = 0;
            }
        }

        Utilities.Secure_DML(steps, Utilities.DML_Action.UPD, schema.Sobjecttype.Step__c);
        Utilities.Secure_DML(jobs, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment_Job__c);
        Utilities.Secure_DML(dos, Utilities.DML_Action.UPD, schema.Sobjecttype.Destination_Org__c);
        Utilities.Secure_DML(new Deployment__c(Id = dId, Deployment_command_sent__c = null), Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment__c);
    }
    public HerokuResult httpGet(String url) {
        try {
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            DeployAPI.setAuthHeaders(req);//to authenticate agains heroku servers
            req.setEndpoint(url);
            req.setMethod('GET');
            HttpResponse res = h.send(req);
            String r = res.getBody();
            return new HerokuResult(true, r, null);
        } catch (System.Exception ex) {
            return new HerokuResult(false, null, ex.getMessage());
        }
    }

    // START FIELD methods
    public static string describeFields(string sObjectName) {
        string availableQueryFields = '';
        try {
            Map<String, Schema.SObjectType> schemaMap = new Map<String, Schema.SObjectType>();
            schemaMap = Schema.getGlobalDescribe();
            Map <String, Schema.SObjectField> fieldMap = schemaMap.get(sObjectName).getDescribe().fields.getMap();
            for (Schema.SObjectField sfield : fieldMap.Values()) {
                schema.describefieldresult dfield = sfield.getDescribe();
                if (String.isBlank(availableQueryFields)) {
                    availableQueryFields = dfield.getName();
                } else {
                    availableQueryFields += ',' + dfield.getName();
                }
            }
            return availableQueryFields;
        } catch (Exception ex) {
            return null;
        }
    }
    // END FIELD methods

    public static PageReference doOauth(Org__c org){
        String urlParameters = '?orgId='+EncodingUtil.urlEncode(org.Id,'UTF-8')+'&url='+EncodingUtil.urlEncode([select API_URL__c from User where id=:userinfo.getUserId()].API_URL__c,'UTF-8');
        if(org.Org_Type__c =='Sandbox') urlParameters += '&sandbox=true';
        if(org.Org_Type__c =='Custom Domain') urlParameters += '&domain='+EncodingUtil.urlEncode(org.Custom_Domain__c,'UTF-8');
        urlParameters += '&copadoOrgId='+EncodingUtil.urlEncode(userinfo.getOrganizationId(),'UTF-8');
        urlParameters += '&copadoUserId='+EncodingUtil.urlEncode(userinfo.getUserId(),'UTF-8');
        urlParameters += '&signature='+EncodingUtil.urlEncode(DeployAPI.encryptAPIKey(userinfo.getOrganizationId()+userinfo.getUserId()),'UTF-8');
        String herokuServer = settings.Server_URL;
        String urlOauth = herokuServer + '/Authorize/sforceLogin'+ urlParameters;
        PageReference pr =new PageReference(urlOauth);
        system.debug(pr);
        return pr;
    }

    public static List<Copado_License__c> getCopadoLicenses(String userName){
        return [SELECT Id, Name, SetupOwnerId, SetupOwner.Name, Enable_CCM__c, Enable_CAD__c, Enable_CST__c, Enable_Copado__c, Enable_CCH__c FROM Copado_License__c WHERE SetupOwner.Name =: userName];
    }

    public static Attachment insertAttachment(blob body, string name, string contentType, string parentId) {
        Attachment att = new Attachment();
        att.Body = body;
        att.Name = name;
        att.ContentType = contentType;
        att.IsPrivate = false;
        att.ParentId = parentId;
        Utilities.Secure_DML(att, Utilities.DML_Action.INS, schema.Sobjecttype.Attachment);
        return att;
    }

    // QUERIES START
    public static Org__c[] getAllOrgs() {
        Org__c[] o = [select id, Test_Frequency__c, name, username__c, password__c, token__c, org_type__c, sfdc_org_id__c, validated_date__c, error__c, Disable_Validation__c from Org__c limit 10000];
        return o;
    }

    public static Git_Repository__c getGitById(string recordId) {
        SObject so = queryAllfields('Git_Repository__c', recordId);
        if (so == null)return null;
        Git_Repository__c o = (Git_Repository__c) so;
        return o;
    }

    public static Release__c getReleaseById(String recordId) {
        SObject so = queryAllfields('Release__c', recordId);
        if (so == null)return null;
        Release__c o = (Release__c) so;
        return o;
    }

    public static External_CI_Setting__c getCISettingById(string recordId) {
        SObject so = queryAllfields('External_CI_Setting__c', recordId);
        if (so == null)return null;
        External_CI_Setting__c o = (External_CI_Setting__c) so;
        return o;
    }

    public static External_CI_Job__c getCIJobById(string recordId) {
        SObject so = queryAllfields('External_CI_Job__c', recordId);
        if (so == null)return null;
        External_CI_Job__c o = (External_CI_Job__c) so;
        return o;
    }

    public static Git_Backup__c getGitBackupById(string recordId) {
        SObject so = queryAllfields('Git_Backup__c', recordId);
        if (so == null)return null;
        Git_Backup__c o = (Git_Backup__c) so;
        return o;
    }

    public static Deployment_Flow__c getDeploymentFlowById(string recordId) {
        SObject so = queryAllfields('Deployment_Flow__c', recordId);
        if (so == null)return null;
        Deployment_Flow__c o = (Deployment_Flow__c) so;
        return o;
    }

    public static Promotion__c getPromotionById(string recordId) {
        SObject so = queryAllfields('Promotion__c', recordId);
        if (so == null)return null;
        Promotion__c o = (Promotion__c) so;
        return o;
    }

    public static User_Story__c getUserStoryById(string recordId) {
        SObject so = queryAllfields('User_Story__c', recordId);
        if (so == null)return null;
        User_Story__c o = (User_Story__c) so;
        return o;
    }

    public static PermissionSet getPermissionSetById(string recordId) {
        SObject so = queryAllfields('PermissionSet', recordId);
        if (so == null)return null;
        PermissionSet o = (PermissionSet) so;
        return o;
    }

    public static Org__c getOrgById(string recordId) {
        List<Org__c> o = [
                select id, name, Test_Frequency__c, username__c,
                        password__c, Metadata_Types__c, token__c, org_type__c,
                        sfdc_org_id__c, validated_date__c, error__c,
                        Disable_Validation__c, Oauth_Signature__c,
                        Validated_Status__c,
                        Last_Apex_Tests_Datetime__c,
                        Last_Apex_Tests_Status__c,
                        Last_Git_Backup_Datetime__c,
                        Last_Git_Backup_Status__c,
                        Custom_Domain__c,
                        Environment__c,
                        Default_Credential__c,
                        is_Developer_Hub_Org__c,
                        Developer_Hub_Org__c,
                        Developer_Hub_Org__r.is_Developer_Hub_Org__c,
                        Default_Scratch_Org_Definition__c
                from Org__c
                where Id = :EncodingUtil.urlEncode(recordId, 'UTF-8')
                limit 1
        ];
        if (o.size() > 0) {
            return o[0];
        }else{
            return new Org__c();
        }
    }
    public static Deployment__c getDeploymentById(string recordId) {
        Deployment__c deployment = [SELECT Count_Completed__c, Completed__c, Deployed__c, CreatedById, CreatedDate, Date__c, IsDeleted, Deployment_Jobs_Count__c, Name, Deployment_command_sent__c, From_Org__c, LastActivityDate, LastModifiedById, LastModifiedDate, OwnerId, Id, SUM_Deployed__c, Schedule__c, Server_URL__c, Status__c, SystemModstamp FROM Deployment__c where Id = :EncodingUtil.urlEncode(recordId, 'UTF-8')];
        return deployment;
    }
    public static Step__c[] getStepsByDeploymentId(string recordId) {
        Step__c[] steps = [select Id, Name, Order__c, Deployment__c, Type__c, dataJson__c, Status__c, CheckOnly__c, Status_Flag__c, Deployment__r.From_Org__c, Branch__c, Commit_Id__c, Commit_Name__c , Git_Repository__c, Git_Repository__r.Name, Run_all_tests__c from Step__c where Deployment__c = :recordId order by Order__c ASC limit 10000];
        return steps;
    }
    public static Step__c getStepById(string recordId) {
        Step__c s = [select Id, Name, Order__c, Deployment__c, Type__c, dataJson__c, Status__c, CheckOnly__c, Status_Flag__c, Deployment__r.From_Org__c from Step__c where Id = :EncodingUtil.urlEncode(recordId, 'UTF-8') limit 1];
        return s;
    }

    public static Map<Id,String> getEnvsAndBranchesOfDeploymentFlow(Id dfId) {
        Map<Id, String> envsAndBranches = new Map<Id, String>(); // Env.Id, Branch_name
        Deployment_Flow__c df = [SELECT Id, Name, Git_Repository__c, Main_Branch__c FROM Deployment_Flow__c WHERE Id = :dfId];
        List<Deployment_Flow_Step__c> steps = [SELECT Source_Environment__c, Branch__c, Destination_Environment__c FROM Deployment_Flow_Step__c WHERE Deployment_Flow__c = :df.Id];
        if(steps.size()>0) {
            for (Deployment_Flow_Step__c step : steps) {
                if (step.Source_Environment__c != null)
                    envsAndBranches.put(step.Source_Environment__c, step.Branch__c);
            }
            // any dest environment not previously set as a source somewhere, is the main env, and matches the main branch.
            for (Deployment_Flow_Step__c step : steps) {
                if (step.Destination_Environment__c != null && !envsAndBranches.containsKey(step.Destination_Environment__c) )
                    envsAndBranches.put(step.Destination_Environment__c, df.Main_Branch__c);
            }
        }
        return envsAndBranches;
    }

    public static List<Deployment_Flow_Step__c> getStepDetailsOfDeploymentFlow(Id dfId) {
        List<Deployment_Flow_Step__c> steps = (List<Deployment_Flow_Step__c>)ExternalCIAPIFactory.queryAllValues('Deployment_Flow_Step__c', 'Deployment_Flow__c', dfId, '', '');
        return steps;
    }

    public static Destination_Org__c[] getDestinationOrgsByDeploymentId(string recordId) {
        Destination_Org__c[] dos = [select Id, Name, Status__c, Deployment__c, To_Org__c,
                                    To_Org__r.Name, To_Org_Name__c, To_Org__r.Validated_Date__c, To_Org__r.Validated_Status__c,
                                    To_Org__r.Last_Apex_Tests_Datetime__c, To_Org__r.Last_Apex_Tests_Status__c,
                                    To_Org__r.Last_Git_Backup_Datetime__c, To_Org__r.Last_Git_Backup_Status__c
                                    from Destination_Org__c where Deployment__c = :EncodingUtil.urlEncode(recordId, 'UTF-8') order by Name ASC limit 10000];
        return dos;
    }
    public static Destination_Org__c getDestinationOrgsById(string recordId) {
        Destination_Org__c dorg = [select Id, Name, Status__c, Deployment__c, To_Org__c,
                                   To_Org__r.Name,  To_Org__r.Last_Apex_Tests_Status__c, To_Org__r.Last_Apex_Tests_Datetime__c,
                                   To_Org__r.Last_Git_Backup_Status__c,  To_Org__r.Last_Git_Backup_Datetime__c
                                   from Destination_Org__c where Id = :EncodingUtil.urlEncode(recordId, 'UTF-8') limit 1];
        return dorg;
    }
    //public static List<Add_on__c> getAllAddons(){
    //    Add_on__c[] addons = [select Id, Name, Description__c, Package_Name__c, Visualforce_page__c from Add_on__c order by Name DESC];
    //    return addons;
    //}
    // QUERIES END

    public class HerokuResult {
        public boolean success {get; set;}
        public string response {get; set;}
        public string errorMessage {get; set;}

        public HerokuResult(boolean b, string r, string em) {
            this.success = b;
            this.response = r;
            this.errorMessage = em;
        }
    }
    public class IsufficientAccessException extends Exception {
    }
    public enum DML_Action {INS, UPD, DEL, UPS}

    private static void HandleDatabaseOperations(Database.SaveResult[] dbsr) {
        for (Database.SaveResult sr : dbsr) {
            if (!sr.isSuccess()) {
                String messages = '';
                for (Database.error er : sr.getErrors()) {
                    messages += er.getMessage() + '  ';
                }
                if (ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, messages));
                } else {
                    throw new DMLException(messages);
                }
            }
        }
    }
    private static void HandleDatabaseOperations(Database.UpsertResult[] dbsr) {
        for (Database.UpsertResult sr : dbsr) {
            if (!sr.isSuccess()) {
                String messages = '';
                for (Database.error er : sr.getErrors()) {
                    messages += er.getMessage() + '  ';
                }
                if (ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, messages));
                } else {
                    throw new DMLException(messages);
                }
            }
        }
    }
    private static void HandleDatabaseOperations(Database.DeleteResult[] dbsr) {
        for (Database.DeleteResult sr : dbsr) {
            if (!sr.isSuccess()) {
                String messages = '';
                for (Database.error er : sr.getErrors()) {
                    messages += er.getMessage() + '  ';
                }
                if (ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, messages));
                } else {
                    throw new DMLException(messages);
                }
            }
        }
    }

    public static List<SObject> Secure_DML(List<SObject> sobjects, DML_Action action, Schema.DescribeSObjectResult stype, Schema.Describefieldresult externalIDField) {
        //US-0001074: FL: to prevent error messages on customer VF pages.
        if(sobjects == null || sobjects.size() == 0){
            //Ignoring permissions
            return sobjects;
        }
        boolean isUpdateable = stype.isUpdateable();
        boolean isCreateable = stype.isCreateable();
        boolean isDeletable = stype.isDeletable();
        boolean isAccessible = stype.isAccessible();
        boolean isCustomSetting = stype.isCustomSetting();
        boolean forceDML = isCustomSetting || Trigger.isExecuting;
        //US-0001123: FL: allow triggers to do DML since they run in system mode.
        if (action == DML_Action.INS) {
            if (isAccessible && isCreateable || forceDML) {
                Database.SaveResult[] srList = Database.insert(sobjects, true);
                HandleDatabaseOperations(srList);
            } else {
                if (ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.INSUFFICENT_ACCESS + ': ' + stype.getName()));
                } else {
                    throw new DMLException(Label.INSUFFICENT_ACCESS + ': ' + stype.getName());
                }
            }

        } else if (action == DML_Action.UPD) {
            if (isAccessible && isUpdateable || forceDML) {
                Database.SaveResult[] srList = Database.update(sobjects, true);
                HandleDatabaseOperations(srList);
            } else {
                if (ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.INSUFFICENT_ACCESS + ': ' + stype.getName()));
                } else {
                    throw new DMLException(Label.INSUFFICENT_ACCESS + ': ' + stype.getName());
                }
            }

        } else if (action == DML_Action.DEL) {
            if (isAccessible && isDeletable || forceDML) {
                Database.DeleteResult[] srList = Database.delete(sobjects, true);
                HandleDatabaseOperations(srList);
            } else {
                if (ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.INSUFFICENT_ACCESS + ': ' + stype.getName()));
                } else {
                    throw new DMLException(Label.INSUFFICENT_ACCESS + ': ' + stype.getName());
                }
            }
        } else if (action == DML_Action.UPS) {
            if (isAccessible && isCreateable && isUpdateable || forceDML) {
                if (externalIDField != null) {
                    Database.UpsertResult[] upr = Database.upsert(sobjects, externalIDField.getSObjectField());
                    HandleDatabaseOperations(upr);
                } else {
                    List<SObject> upds = new List<SObject>();
                    List<SObject> ins = new List<SObject>();
                    for (SObject s : sobjects) {
                        if (s.id == null) {
                            ins.add(s);
                        } else {
                            upds.add(s);
                        }
                    }
                    if (upds.size() > 0) {
                        Database.SaveResult[] srList = Database.update(upds);
                        HandleDatabaseOperations(srList);
                    }
                    if (ins.size() > 0) {
                        Database.SaveResult[] srList = Database.insert(ins);
                        HandleDatabaseOperations(srList);
                    }
                }
            } else {
                if (ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.INSUFFICENT_ACCESS + ': ' + stype.getName()));
                } else {
                    throw new DMLException(Label.INSUFFICENT_ACCESS + ': ' + stype.getName());
                }
            }
        }
        return sobjects;
    }


    public static List<SObject> Secure_DML(List<SObject> sobjects, DML_Action action, Schema.DescribeSObjectResult stype) {
        List<SObject> SObjectList = Secure_DML(sobjects, action, stype, null);
        return SObjectList;
    }
    public static SObject Secure_DML(SObject sob, DML_Action action, Schema.DescribeSObjectResult stype, Schema.Describefieldresult externalIDField) {
        List<SObject> r = Secure_DML(new List<SObject> {sob}, action, stype, externalIDField);
        if (r != null)return r[0];
        return null;
    }

    public static SObject Secure_DML(SObject sob, DML_Action action, Schema.DescribeSObjectResult stype) {
        List<SObject> r = Secure_DML(new List<SObject> { sob}, action, stype);
        if (r != null)return r[0];
        return null;
    }
    public static Integer randomInteger(Integer min, Integer max) {
        Integer i = Math.mod(Integer.valueof(math.random() * 10 * (max + ''.length())), max);
        WHILE(i < min) {
            i += min;
            if (i > max) i -= max;
        }
        return i;
    }
    public static void sendEmail(String toAddress, String subject, String body) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {toAddress};
        mail.setToAddresses(toAddresses);
        mail.setSenderDisplayName(UserInfo.getName());
        mail.setSubject(subject);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    public static Map<String, String> getAllFields(String sObjectName) {


        //Ignore the PermissionSet object for the PermissionSet Explorer
        if (sObjectName != Label.PERMISSION_SET_SOBJECT_NAME) sObjectName = Settings.ns + sObjectName;
        Map<String, String> result = new Map<String, String>();
        if (!Schema.getGlobalDescribe().containsKey(sObjectName)) {
            System.debug('INVALID OBJECT ' + sObjectName);
            return null;
        }
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().SObjectType.getDescribe().fields.getMap();

        Set<String> accessiblefields = new Set<String>();

        for (Schema.SObjectField field : fields.values()) {
            if (field.getDescribe().isAccessible()) {
                accessiblefields.add(field.getDescribe().getName());
            }
        }

        //Now we do the same for fields in the FieldSets
        Map<String, Schema.FieldSet> fsMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().SObjectType.getDescribe().fieldSets.getMap();

        for (Schema.FieldSet fs: fsMap.values()) {
            for (Schema.FieldSetMember fsm: fs.getFields()) {
                accessiblefields.add(fsm.getFieldPath());
            }
        }

        String allfields = '';

        for (String fieldname : accessiblefields)
            allfields += fieldname + ',';

        allfields = allfields.subString(0, allfields.length() - 1);

        System.Debug('getAllFieldsResult = ' + allfields);

        result.put(Label.OBJECT, sObjectName);
        result.put(Label.FIELDS, allfields);
        return result;
    }
    public static SObject queryAllfields(String sObjectName, String recordId) {
        recordId = EncodingUtil.urlEncode(recordId, 'UTF-8');
        Map<String, String> d = getAllFields(sObjectName);

        String queryString = 'SELECT ' + d.get(Label.FIELDS) + ' FROM ' + d.get(Label.OBJECT) + ' WHERE ID =:recordId';
        System.debug('QUERY: ' + queryString);
        List<SObject> sos = Database.query(queryString);
        if (sos.size() > 0) return sos.get(0);
        return null;
    }
    /*
    ** This method is to be used whenever we need an API Capable Session Id, normally used when doing something from LEX
    **
     */
    public static String getClassicSessionId() {
        String content = '';

        content = Test.IsRunningTest() ? '{"sId":"TestMethodKey123"}' : Page.ClassicSessionId.getContent().toString();

        /*if (Test.IsRunningTest()) {
            content = '{"sId":"TestMethodKey123"}';
        } else {
            content = Page.ClassicSessionId.getContent().toString();
        }*/
        Map<String, Object> jMap = (Map<String, Object>)JSON.deserializeUntyped(content);
        return (String)jMap.get('sId');
    }

    public static List<String> getPicklistValues(String sObjectName, String Field_name) {

        sObjectName = Settings.ns + sObjectName;
        List<String> lstPickvals = new List<String>();
        System.Debug('sObjectName = ' + sObjectName + ' -- Field name = ' + Field_name);
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sObjectName);
        Sobject Object_name = targetType.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType();
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
        List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues();

        for (Schema.PicklistEntry a : pick_list_values) {
            lstPickvals.add(a.getValue());
        }

        return lstPickvals;
    }

    /**
     * @param Id UserId: this user will be @ mentioned in the chatter post.
     * @param String chatterMessage: chatter post text.
     * @param Id recordId: chatter will post the notification in this record.
     */
    public static void notifyUsingChatterWithAtMention(Id userId, String chatterMessage, Id recordId) {
        /* ConnectApi class is not accessible from Tests Classes */
        if (!Test.isRunningTest()) {
            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

            mentionSegmentInput.id = userId;
            messageBodyInput.messageSegments.add(mentionSegmentInput);

            textSegmentInput.text = chatterMessage;
            messageBodyInput.messageSegments.add(textSegmentInput);

            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = recordId;

            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        }
    }

    /**
     * @param String sObjectType: API name of the Object to be checked.
     * @returns Boolean: true if it's enabled for both Org and Object, false otherwise. No exception it's thrown to prevent stopping a process.
     */
    public static Boolean isChatterEnabled(String sObjectType) {
        List<String> types = new List<String>();
        types.add(sObjectType);
        List<Schema.DescribeSobjectResult> results = Schema.describeSObjects(types);
        if (!results[0].feedEnabled || !Schema.SObjectType.User.isFeedEnabled()) {
            System.Debug(System.Label.CHATTER_NOT_ENABLED);
            return false;
        }
        else {
            return true;
        }
    }

    public static list<selectOption> selectOptionSortByLabel(list<selectOption>selectOptionsToSort) {
        if (selectOptionsToSort == null || selectOptionsToSort.size() <= 1) {
            return selectOptionsToSort;
        }
        List<SelectOption> lessSelectOption = new List<SelectOption>();
        List<SelectOption> greaterSelectOption = new List<SelectOption>();
        integer pivot = selectOptionsToSort.size() / 2;

        //save the pivot and remove it from the selectOption list
        SelectOption pivotValue = selectOptionsToSort[pivot];
        selectOptionsToSort.remove(pivot);
        for (selectOption SO : selectOptionsToSort) {
            if (SO.getLabel() <= pivotValue.getLabel()) {
                lessSelectOption.add(SO);
            } else if (SO.getLabel() > pivotValue.getLabel()) {
                greaterSelectOption.add(SO);
            }
        }
        list<selectOption> sortedSelectOptions = new list<selectOption>();
        sortedSelectOptions.addAll(selectOptionSortByLabel(lessSelectOption));
        sortedSelectOptions.add(pivotValue);
        sortedSelectOptions.addAll(selectOptionSortByLabel(greaterSelectOption));
        return SortedSelectOptions;
    }


}