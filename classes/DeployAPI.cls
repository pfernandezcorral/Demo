public with sharing class DeployAPI {
    public static String copadoURL = Settings.Server_URL;
    public class ApplicationException extends Exception {}
    public static Map<String, Object> orgMap;

    @Future(callout=true)
    public static void deploy(List<Id> ids, String sid){
        for(Id depId:ids){
            deployNow(depId, sid);
        }
    }
    //@Future(callout=true)
    public static void deploy(Id depId, String sid){
        deployNow(depId, sid);
    }
    public static void cancelDeployment(Id depId){
        List<Deployment_Job__c> djs = [select id from Deployment_Job__c where Step__r.Deployment__c = :depId and Status__c in ('Pending','Not started')];
        for(Deployment_Job__c d:djs)d.Status__c='Cancelled';
        if(djs.size()>0)Utilities.Secure_DML(djs,Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment_Job__c);
    }
    public static void deployNow(Id depId, String sid){
        String copadoOrgId = UserInfo.getOrganizationId();
        String copadoUserId = [select OwnerId from Deployment__c where Id = :depId].OwnerId;
        String url = copadoURL+'/json/v1/deployNow/'+depId+'?copadoOrgId='+copadoOrgId+'&copadoUserId='+copadoUserId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
        //list only results json files from jobs to be re-deployed. so result are not lost for previously deployed jobs
        List<String> pendingJobs = new List<String>();
        for(Deployment_Job__c dj: [select id from Deployment_Job__c where step__r.Deployment__c = :depId and Status__c ='Pending'])pendingJobs.add(dj.id+'.json');

        List<Attachment> atts = [select id,name from Attachment where (name in :pendingJobs or name like 'ERRORs%')and parentId = :depId and (not (name like 'OLD_%'))];
        for(Attachment at:atts){
            at.Name = 'OLD_'+at.Name;
        }
        if(atts.size()>0)Utilities.Secure_DML(atts, Utilities.DML_Action.UPD, schema.Sobjecttype.Attachment);

        //reset status of deployment jobs
        Set<Id> djIds = new Set<Id>();
        for(Deployment_Job__c dj:[Select Id from Deployment_Job__c where Step__r.Deployment__c = :depId])djIds.add(dj.Id);
        atts = [select id,name from Attachment where (name like '%_STATUS_COPADO')and parentId IN :djIds and (not (name like 'OLD_%'))];
        for(Attachment at:atts){
            at.Name = 'OLD_'+at.Name;
        }
        if(atts.size()>0)Utilities.Secure_DML(atts, Utilities.DML_Action.UPD, schema.Sobjecttype.Attachment);
    }
    public static void backupNow(Id backupId){
        DeployAPI.backupNow(backupId,'', false, false);
    }
    public static void backupNow(Id backupId, String comment, Boolean applyEnvVars, Boolean applyYAML){
        Git_Backup__c bk = [select Org__c, Metadata_Types__c from Git_Backup__c where id=:backupId];
        String copadoOrgId = UserInfo.getOrganizationId();
        String copadoUserId = [select OwnerId from Org__c where id =:bk.Org__c].OwnerId;
        String orgId = bk.Org__c;
        String url = copadoURL+'/json/v1/backupNow/'+backupId+'?message='+EncodingUtil.urlEncode(comment,'UTF-8')+'&copadoOrgId='+copadoOrgId+'&copadoUserId='+copadoUserId+'&orgId='+orgId+'&applyEnvVars='+applyEnvVars+'&applyYAML='+applyYAML;
        if(bk.Metadata_Types__c != null && bk.Metadata_Types__c !='')url += '&filter='+ EncodingUtil.urlEncode(bk.Metadata_Types__c,'UTF-8');
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }

    public static void executeCI(Id ciId){
        String copadoOrgId = UserInfo.getOrganizationId();
        String copadoUserId = UserInfo.getUserId();
        String endP = [Select Id, API_URL__c from User where Id =: UserInfo.getUserId()].API_URL__c;
        //String url = copadoURL+'/json/v1/buildTaskExec/'+ciId+'?sid='+UserInfo.getSessionId()+'&url='+EncodingUtil.urlEncode(endP,'UTF-8')+'&copadoOrgId='+copadoOrgId+'&copadoUserId='+copadoUserId;
        String url = copadoURL+'/json/v1/buildTaskExec/'+ciId+'?copadoOrgId='+copadoOrgId+'&copadoUserId='+copadoUserId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setHeader('Content-Type' ,'application/json');
        req.setMethod('POST');
        req.setBody('{"commits":[]}');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }

    @Future(callout=true)
    public static void deployBuildTask(Set<Id> btIds, String sessionId){
        String copadoOrgId = UserInfo.getOrganizationId();
        String copadoUserId = UserInfo.getUserId();
        String endP = [Select Id, API_URL__c from User where Id =: UserInfo.getUserId()].API_URL__c;

        for(Id btId:btIds){
            //String url = copadoURL+'/json/v1/deployBuildTask/'+btId+'?sid='+sessionId+'&url='+EncodingUtil.urlEncode(endP,'UTF-8')+'&copadoOrgId='+copadoOrgId+'&copadoUserId='+copadoUserId;
            String url = copadoURL+'/json/v1/deployBuildTask/'+btId+'?copadoOrgId='+copadoOrgId+'&copadoUserId='+copadoUserId;
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            setAuthHeaders(req);//to authenticate agains heroku servers
            req.setEndpoint(url);
            req.setMethod('POST');
            req.setHeader('Content-Type' ,'application/json');
            req.setBody(JSON.serialize(btIds));
            HttpResponse res = h.send(req);
            HerokuResponse hr = new HerokuResponse(res);
        }

    }

    public static void getCommits(Id backupId){
        String endP = [Select Id, API_URL__c from User where Id =: UserInfo.getUserId()].API_URL__c;
        String url = copadoURL+'/json/v1/gitCommits/'+backupId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }

    public static void testNow(Id orgId){
        String copadoOrgId = UserInfo.getOrganizationId();
        String copadoUserId = [select OwnerId from Org__c where Id = :orgId].OwnerId;
        String url = copadoURL+'/json/v1/testNow/'+orgId+'?copadoOrgId='+copadoOrgId+'&copadoUserId='+copadoUserId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }
    //seems like is not used
    public static Map<String,Object> estimateDeploy(Id depId, String sid){
        String copadoOrgId = UserInfo.getOrganizationId();
        String copadoUserId = UserInfo.getUserId();
        String url = copadoURL+'/json/v1/estimateDeploy/'+depId+'?copadoOrgId='+copadoOrgId+'&copadoUserId='+copadoUserId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
        String r = res.getBody();
        Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(r);
        return m;
    }
    public static Integer getCredits(){
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(copadoURL+'/?nosid=1');
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
        Map<String, Object> fullMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        orgMap = (Map<String, Object>)fullMap.get('customerOrg');
        return (Integer)orgMap.get('credits');
    }
    //seems like is not used
    @Future(callout=true)
    public static void saveDeploy(Id deployId, String sid){
        String url = copadoURL+'/json/v1/saveDeploy/'+deployId+'?nosid=1';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }
    @Future(callout=true)
    public static void cleanDeploy(Id deployId){
        String url = copadoURL+'/json/v1/cleanDeploy/'+EncodingUtil.urlEncode(deployId,'UTF-8');
        String status = [select Status__c from Deployment__c where Id=:deployId].Status__c;
        url += '?status='+EncodingUtil.urlEncode(status,'UTF-8');
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);

    }
    @Future(callout=true)
    public static void deployJob(List<Id> ids, String sid){
        Map<Id,Deployment_Job__c> mp = new Map<Id,Deployment_Job__c>([select id,step__r.deployment__c from Deployment_Job__c where id in:ids]);
        system.debug('###### '+mp);
        for(Id jobId:ids){
            system.debug('LOOP ##### job id '+jobId);
            String url = copadoURL+'/json/v1/deployJob/'+jobId+'?deployId='+mp.get(jobId).step__r.deployment__c;
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            setAuthHeaders(req);//to authenticate agains heroku servers
            req.setEndpoint(url);
            req.setMethod('GET');
            HttpResponse res = h.send(req);
            HerokuResponse hr = new HerokuResponse(res);
        }
    }
    public static boolean validateOrg(Id orgId){
        String endP = [Select Id, API_URL__c from User where Id =: UserInfo.getUserId()].API_URL__c;
        String url = copadoURL+'/json/v1/validateOrg/'+orgId+'?setProfile=true';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        try{
            HerokuResponse hr = new HerokuResponse(res);
            system.debug(hr);
            Map<String, Object> mapa = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            return mapa.get('organizationId')!=null;
        }
        catch(Exception e){
            system.debug(e);
            return false;
        }
    }
    public class validateGitResult {
        public Boolean success {get;set;}
        public String message {get;set;}
    }
    public static validateGitResult validateGit(Id gitId){
        String url = copadoURL+'/json/v1/validateGit/?nosid=1';
        Git_Repository__c git = [select Id, URI__c, Username__c, Password__c from Git_Repository__c where id=:EncodingUtil.urlEncode(gitId,'UTF-8')];
        url += '&uri='+EncodingUtil.urlEncode(git.URI__c,'UTF-8');
        if(String.isNotBlank(git.Username__c)) url += '&un='+EncodingUtil.urlEncode(git.Username__c,'UTF-8');
        if(String.isNotBlank(git.Password__c))url += '&pw='+EncodingUtil.urlEncode(git.Password__c,'UTF-8');
        url += '&repoId='+EncodingUtil.urlEncode(git.Id,'UTF-8');
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        system.debug(req);
        system.debug(res.getBody());
        validateGitResult result = new validateGitResult();
        try{
            HerokuResponse hr = new HerokuResponse(res);
            result.success = true;
            result.message = Label.OK_CREDENTIALS;
        } catch(Exception e) {
            result.success = false;
            result.message = Label.WRONG_CREDENTIALS+': '+e.getMessage();
        }
        return result;
    }
    public static boolean validateExternalCI(Id externalCIId){
        //TODO TODO
        return true;
    }
    public static Org__c getCustomerOrg(){
        return getCustomerOrg(UserInfo.getUserId());
    }
    public static Org__c getCustomerOrg(String uid){
        String oid = UserInfo.getOrganizationId();
        uid = uid == null?UserInfo.getUserId():uid;
        String key = oid+'_'+uid;
        List<Org__c> ls = [select id from Org__c where SFDC_Org_ID__c=:oid or SFDC_Org_ID__c=:key];
        Org__c copadoOrg = ls.size()>0?ls.get(0):null;
        return copadoOrg;
    }
    class ServerException extends Exception {}
    public class HerokuResponse{
        public boolean success{get;set;}
        public String message{get;set;}
        public HerokuResponse(HttpResponse res){
            if(res.getStatusCode()!=null){
                System.debug('@@@ json = ' + res.getBody());
                System.debug(res.getBody());

                Map<String, Object> fullMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                success = fullMap.get('error')==null;
                if(success){
                    message = (String)fullMap.get('ok');
                } else {
                    message = (String)fullMap.get('error');
                }
                System.debug((String)fullMap.get('error'));
            }
            System.debug('@@@ success: ' + success + ' message: ' + message);
            if(!success)throw new ServerException(message);
        }
    }
    public static String getAuthToken(){
        String sid = '<sessionId might change>';//userinfo.getSessionId()!=null?userinfo.getSessionId():'';
        String cdate = Datetime.now().formatGMT('yyyy-MM-dd');
        String myData =  'Copado Deployer by Copado Ltd'+userinfo.getUserId()+userinfo.getOrganizationId()+sid+cdate;
        Blob hash = Crypto.generateDigest('MD5',Blob.valueOf(myData));
        return EncodingUtil.convertToHex(hash);
    }
    public static void setAuthHeaders (HttpRequest req){
        req.setHeader('userId', userinfo.getUserId());
        req.setHeader('orgId', userinfo.getOrganizationId());
        //req.setHeader('sessionId', userinfo.getSessionId()!=null?userinfo.getSessionId():'');
        req.setHeader('token', getAuthToken());
        req.setTimeout(120000);
    }
    public static List<String> metadataTypes(Id orgId, String sid){
        String url = copadoURL+'/json/v1/metadataTypes/'+orgId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        system.debug(req);
        system.debug(res.getBody());
        String r = res.getBody();
        List<String> mt = (List<String>)JSON.deserialize(r,List<String>.class);
        mt.sort();
        return mt;
    }

    /*
    retrieve the available features for this installation. features are in heroku database which are
    synchronized from main Copado salesforce APO org.
    */
    public static void checkSyncFeatures(){
        //if features has been updated today skip update
        System.debug('Checking Features sync ....');
        List<Feature__c> existing = Feature__c.getall().values();
        System.debug('Feature update from LMO data. Existing: ' + existing.size());
        syncFeaturesNow();
    }
    public static void checkSyncLicenses(){
        System.debug('Using LMO for License update. ');
        syncLicensesNow();
    }

    public static void syncFeaturesNow(){
        //US-0001524 features are now handled by FMA/LMO standard features. No need to callout the backend.
        List<Feature__c> featureList = new List<Feature__c>();
        //LMO controlled features
        Integer eeLicensesInteger = FeatureManagement.checkPackageIntegerValue('EE_Licenses_Enabled');
        Integer cadLicensesInteger = FeatureManagement.checkPackageIntegerValue('CAD_Licenses_Enabled');
        Integer ccmLicensesInteger = FeatureManagement.checkPackageIntegerValue('CCM_Licenses_Enabled');
        Integer cstLicensesInteger = FeatureManagement.checkPackageIntegerValue('CST_Licenses_Enabled');
        Integer cchLicensesInteger = FeatureManagement.checkPackageIntegerValue('CCH_Licenses_Enabled');
        Boolean multiLicense = eeLicensesInteger >0 && (cadLicensesInteger>0 || ccmLicensesInteger>0 || cstLicensesInteger>0 || cchLicensesInteger>0);

        //CBM
        Feature__c cbmFeature = Feature__c.getInstance('Branch Management');
        if(cbmFeature == null){
            cbmFeature = new Feature__c(name = 'Branch Management');
        }
        cbmFeature.Enabled__c = FeatureManagement.checkPackageIntegerValue('CBM_Branches') > 0;
        cbmFeature.Expiration_Date__c = null;
        cbmFeature.Quantity__c =  FeatureManagement.checkPackageIntegerValue('CBM_Branches');
        featureList.add(cbmFeature);
        //CCM
        Feature__c ccmFeature = Feature__c.getInstance('Change Management');
        if(ccmFeature == null){
            ccmFeature = new Feature__c(name = 'Change Management');
        }
        ccmFeature.Enabled__c = !multiLicense || ccmLicensesInteger > 0 || cadLicensesInteger > 0;
        ccmFeature.Expiration_Date__c = null;
        ccmFeature.Quantity__c =  null;
        featureList.add(ccmFeature);
        //CST
        Feature__c cstFeature = Feature__c.getInstance('Selenium Testing');
        if(cstFeature == null){
            cstFeature = new Feature__c(name = 'Selenium Testing');
        }
        cstFeature.Enabled__c = cstLicensesInteger > 0;
        cstFeature.Expiration_Date__c = null;
        cstFeature.Quantity__c =  null;
        featureList.add(cstFeature);
        //CCH
        Feature__c cchFeature = Feature__c.getInstance('Compliance Hub');
        if(cchFeature == null){
            cchFeature = new Feature__c(name = 'Compliance Hub');
        }
        cchFeature.Enabled__c = cchLicensesInteger > 0;
        cchFeature.Expiration_Date__c = null;
        cchFeature.Quantity__c =  null;
        featureList.add(cchFeature);

        //Default, legacy features always enabled since there is no more Professional Edition.
        List<String> featuresStrings = new List<String>{'Apex Test', 'Continuous Integration','Full Permission Sets step','Full Profiles step','Git Backup','Git MetaData','Org Difference','Snapshot Difference','Full Translations step'};
        for(String featureName : featuresStrings){
            Feature__c cs = Feature__c.getInstance(featureName);
            if(cs == null){
                cs = new Feature__c(name = featureName);
            }
            cs.Enabled__c = true;
            //we need to remove the expiration from the Feature list UI.
            cs.Expiration_Date__c = null;
            cs.Quantity__c = null;
            featureList.add(cs);
        }

        Utilities.Secure_DML(featureList, Utilities.DML_Action.UPS, schema.Sobjecttype.Feature__c);
    }
    public static void syncLicensesNow(){
        System.debug(' Starting to sync Settings also...');
        LicenseManagerController lmc = new LicenseManagerController();
        System.debug(' Finished using LMO feature parameters');
    }
    public static String createAPIKeys(){
        String url = copadoURL+'/json/v1/createAPIKey?nosid=1';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        return res.getBody();
    }
    public static void createAPIKey(){
        String url = copadoURL+'/json/v1/createAPIKey?nosid=1';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        //HerokuResponse hr = new HerokuResponse(res);
        Map<String, Object> mapa = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        String key = (String)mapa.get('api_key');
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        ps.API_Key__c = encryptAPIKey(key);
        Utilities.Secure_DML(ps, Utilities.DML_Action.UPS, schema.Sobjecttype.Personal_Settings__c);
    }
    private static Blob cryptoKey {get{
        if(!String.isEmpty(Settings__c.getOrgDefaults().CryptoKey__c)){
            return EncodingUtil.base64Decode(Settings__c.getOrgDefaults().CryptoKey__c);
        }else{
            String metaKey =  [SELECT Id, DeveloperName, Text_Field__c  FROM Copado_Protected_Settiing__mdt WHERE DeveloperName = 'Deprecated_Key' LIMIT 1].Text_Field__c;
            return EncodingUtil.base64Decode(metaKey);
        }
    }set;}

    //takes a plain text api key and encrypt it using AES256. Finally base64 encode to be saved as Text.
    public static String encryptAPIKey(String clearAPIKey){
        if(String.isBlank(clearAPIKey))return null;
        Blob data = Blob.valueOf(clearAPIKey);
        return EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', DeployAPI.cryptoKey , data));
    }
    //takes a base64 text
    public static String decryptAPIKey(String APIKey){
        if(String.isBlank(APIKey))return null;
        Blob encryptedData = EncodingUtil.base64Decode(APIKey);
        return Crypto.decryptWithManagedIV('AES256', DeployAPI.cryptoKey, encryptedData).toString();
    }
    //read encrypted user api key and return it decrypted
    public static String getUserAPIKey(){
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        return decryptAPIKey(ps.API_Key__c);
    }
    public static String createSSHKey(String parentId){
        try{
            if(String.isBlank(parentId)){
                return '{"error":"The parentId variable was not specified.  Please contact Copado Solutions support. Error code: DeployAPI.createSSHkey"}';
            }
            String endP = [Select Id, API_URL__c from User where Id =: UserInfo.getUserId()].API_URL__c;
            String url = copadoURL+'/json/v1/keygen?parentId='+parentId;
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            setAuthHeaders(req);//to authenticate agains heroku servers
            req.setEndpoint(url);
            req.setMethod('POST');
            HttpResponse res = h.send(req);
            HerokuResponse hr = new HerokuResponse(res);
            return res.getBody();
        }
        catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
            return null;
        }
    }
    public static void getCommitsFromRepo(Id repositoryId, String branch){
        if(String.isBlank(branch))branch = 'master';
        String url = copadoURL+'/json/v1/gitCommitsFromRepo/'+repositoryId+'?branch=' +branch;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
    }

    @future(callout=true)
    public static void deployPromotionAsync(Id promotionId, String userStoryName, boolean checkOnly, boolean singleStep, String testLevel){
        deployPromotion(promotionId,userStoryName,checkOnly,singleStep,testLevel);
    }

    //@future(callout=true)
    public static void deployPromotion(Id promotionId, String userStoryName, boolean checkOnly, boolean singleStep, String testLevel){
        System.debug('### Start DeployPromotion Callout...');
        testLevel = (String.isBlank(testLevel))?'NoTestRun':testLevel;
        String destEnv = [select Destination_Environment__r.Name from Promotion__c where Id = :promotionId].Destination_Environment__r.Name;
        String deploymentName = 'CD: ' + (checkOnly?'Validate':'Deploy') + ' - ' + userStoryName + ' ➠ ' + destEnv;
        String url = copadoURL+'/json/v1/promote/'+promotionId+'?deploy=true&deploymentName='+EncodingUtil.urlEncode(deploymentName,'UTF-8')+'&checkOnly='+checkOnly+'&singleStep='+singleStep+'&testLevel='+testLevel;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setEndpoint(url);
        req.setMethod('POST');
        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);

        System.debug('### Heroku Response: '+hr);
    }


    public static void orgCodeAnalysis(Id orgId){
        List<Org__c> org = [SELECT Environment__c
        FROM Org__c
        WHERE Id = :orgId LIMIT 1];

        if (org.isEmpty()) {
            throw new ApplicationException(Label.ORG_NOT_FOUND);
        }

        List<Deployment_Flow_Step__c> flow = [SELECT Deployment_Flow__r.Static_Code_Analysis_Settings__c
        FROM Deployment_Flow_Step__c
        WHERE (Source_Environment__c = :org[0].Environment__c OR Destination_Environment__c = :org[0].Environment__c)
        AND Deployment_Flow__r.Static_Code_Analysis_Settings__c != null LIMIT 1];

        if (flow.isEmpty()) {
            throw new ApplicationException(Label.SCA_SETTINGS_NOT_FOUND);
        }
        String url = copadoURL+'/json/v1/analyseStaticCode/';
        url += orgId;
        url += '?settingsId='+flow[0].Deployment_Flow__r.Static_Code_Analysis_Settings__c;
        System.Debug('API callout = ' + url);
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setHeader('Content-Type' ,'application/json');
        req.setEndpoint(url);
        req.setMethod('POST');

        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
        system.debug(req);
        system.debug(res.getBody());
        system.debug(hr);

    }
    public static void usCodeAnalysis(Id orgId, Id usId) {
        //Retrieve list of Apex classes to be analyzed
        List<String> gitClasses = new List<String>();
        List<String> metaClasses = new List<String>();
        Set<String> gitDeletes = new Set<String>();
        try {
            List<Attachment> attachments = [SELECT Id, Body FROM Attachment WHERE Name = 'MetaData' AND ParentId = :usId];
            if(!attachments.isEmpty()) {
                List<MetaData> metas = (List<MetaData>)JSON.deserialize(attachments[0].Body.toString(), List<MetaData>.class);
                for (MetaData m: metas) {
                    if (m.t == 'ApexClass') {
                        metaClasses.add(m.n);
                    }
                }
            }

            attachments = [SELECT Id, Body FROM Attachment WHERE Name = 'Delete MetaData' AND ParentId = :usId];
            if(!attachments.isEmpty()) {
                String attBody = '{ \"att\": ' + attachments[0].Body.toString() + '}';
                System.Debug('attBody = ' + attBody);
                GitWrapper gitMetas = (GitWrapper)JSON.deserialize(attBody, GitWrapper.class);
                for (GitMetaData m: gitMetas.att) {
                    if (m.t == 'ApexClass') {
                        gitDeletes.add(m.n);
                    }
                }
            }

            attachments = [SELECT Id, Body FROM Attachment WHERE Name = 'Git MetaData' AND ParentId = :usId];
            if(!attachments.isEmpty()) {
                String attBody = '{ \"att\": ' + attachments[0].Body.toString() + '}';
                System.Debug('attBody = ' + attBody);
                GitWrapper gitMetas = (GitWrapper)JSON.deserialize(attBody, GitWrapper.class);
                for (GitMetaData m: gitMetas.att) {
                    if (m.t == 'ApexClass' && !gitDeletes.contains(m.n)) {
                        gitClasses.add(m.n);
                    }
                }
            }
        }
        catch (Exception e) {
            throw new ApplicationException(Label.PROBLEM_RETRIEVING_META_ATTACH);
        }

        List<User_Story__c> userStories = [SELECT Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c,
                Project__r.Deployment_Flow__r.Git_Repository__c,
                Environment__c, Project__r.Deployment_Flow__c, Name
        FROM User_Story__c
        WHERE Id = :usId LIMIT 1];

        if (userStories.isEmpty()) {
            throw new ApplicationException(Label.USER_STORY_NOT_FOUND);
        }
        else {
            if (userStories[0].Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c == null) {
                throw new ApplicationException(Label.SCA_SETTINGS_NOT_FOUND);
            }
        }

        if (gitClasses.isEmpty() && metaClasses.isEmpty()) {
            throw new ApplicationException(Label.METADATA_NOT_FOUND);
        }
        else {
            PayloadWrapper pw = new PayloadWrapper();
            pw.gitMetadata = gitClasses;
            pw.metadata = metaClasses;
            String url = copadoURL+'/json/v1/analyseStaticCode/';
            url += orgId;
            url += '?userStoryId='+usId;
            if (userStories[0].Project__r.Deployment_Flow__r.Git_Repository__c != null) {
                url += '&repositoryId='+userStories[0].Project__r.Deployment_Flow__r.Git_Repository__c;
                url += '&branch=feature/' + userStories[0].Name;
            }
            url += '&settingsId='+userStories[0].Project__r.Deployment_Flow__r.Static_Code_Analysis_Settings__c;
            System.Debug('API callout = ' + url);
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            setAuthHeaders(req);//to authenticate agains heroku servers
            req.setEndpoint(url);
            req.setHeader('Content-Type' ,'application/json');
            req.setMethod('POST');
            req.setBody(JSON.serializePretty(pw));
            System.Debug('Payload: ' + JSON.serializePretty(pw));

            HttpResponse res = h.send(req);
            HerokuResponse hr = new HerokuResponse(res);
            system.debug(req);
            system.debug(res.getBody());
            system.debug(hr);
        }
    }

    public class MetaWrapper {
        List<MetaData> att {get;set;}
    }

    public class GitWrapper {
        List<GitMetaData> att {get;set;}
    }

    public class MetaData {
        public String n {get;set;}
        public Boolean s {get;set;}
        public String d {get;set;}
        public String b {get;set;}
        public String cd {get;set;}
        public String cb {get;set;}
        public String t {get;set;}
    }

    public class GitMetaData {
        public String t {get;set;}
        public String n {get;set;}
        public String cmm {get;set;}
    }

    public class PayloadWrapper {
        List<String> gitMetadata {get;set;}
        List<String> metadata {get;set;}
    }

    public static void orgComplianceScan(Id orgId){
        List<Org__c> org = [SELECT Environment__c
        FROM Org__c
        WHERE Id = :orgId LIMIT 1];

        if (org.isEmpty()) {
            throw new ApplicationException(Label.ORG_NOT_FOUND);
        }

        List<Environment__c> environment = [SELECT Id, Compliance_Rule_Group__c FROM Environment__c WHERE Id = :org[0].Environment__c LIMIT 1];

        if (environment.isEmpty() || environment[0].Compliance_Rule_Group__c == null) {
            throw new ApplicationException(Label.COMPLIANCE_SETTING_NOT_FOUND);
        }
        String url = copadoURL+'/json/v1/scanCompliance';
        url += '?orgId='+orgId;
        System.Debug('API callout = ' + url);
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setHeader('Content-Type' ,'application/json');
        req.setEndpoint(url);
        req.setMethod('GET');

        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
        system.debug(req);
        system.debug(res.getBody());
        system.debug(hr);
    }
    public static void gitBackupComplianceScan(Id gitBackupId){
        List<Git_Backup__c> gitBackup = [SELECT Id, Org__r.Environment__c
        FROM Git_Backup__c
        WHERE Id = :gitBackupId LIMIT 1];

        if (gitBackup.isEmpty()) {
            throw new ApplicationException(Label.GIT_BACKUP_NOT_FOUND);
        }

        List<Environment__c> environment = [SELECT Id, Compliance_Rule_Group__c FROM Environment__c WHERE Id = :gitBackup[0].Org__r.Environment__c LIMIT 1];

        if (environment.isEmpty() || environment[0].Compliance_Rule_Group__c == null) {
            throw new ApplicationException(Label.COMPLIANCE_SETTING_NOT_FOUND);
        }

        String url = copadoURL+'/json/v1/scanCompliance';
        url += '?gitBackupId='+gitBackupId;
        System.Debug('API callout = ' + url);
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate agains heroku servers
        req.setHeader('Content-Type' ,'application/json');
        req.setEndpoint(url);
        req.setMethod('GET');

        HttpResponse res = h.send(req);
        HerokuResponse hr = new HerokuResponse(res);
        system.debug(req);
        system.debug(res.getBody());
        system.debug(hr);
    }
    public static void usComplianceScan(Id orgId, Id usId) {
        List<User_Story__c> userStories = [SELECT Name, Environment__r.Compliance_Rule_Group__c, Project__r.Deployment_Flow__c,
                Project__r.Deployment_Flow__r.Git_Repository__c,
                Release__r.Project__r.Deployment_Flow__r.Git_Repository__c
        FROM User_Story__c
        WHERE Id = :usId LIMIT 1];

        if (userStories.isEmpty()) {
            throw new ApplicationException(Label.USER_STORY_NOT_FOUND);
        } else {
            if (userStories[0].Environment__r.Compliance_Rule_Group__c == null) {
                throw new ApplicationException(Label.COMPLIANCE_SETTING_NOT_FOUND);
            }
        }

        // Metadata attachments are retrieved in the backend. Verify that the attachments exist.
        List<Attachment> attachments = new List<Attachment>();
        try {
            attachments = [SELECT Id, Body FROM Attachment WHERE ParentId = :usId AND (Name = 'MetaData' OR Name = 'Delete MetaData' OR  Name = 'Git MetaData')];
            if(!attachments.isEmpty()) {

            }
        } catch (Exception e) {
            throw new ApplicationException(Label.PROBLEM_RETRIEVING_META_ATTACH);
        }

        if (attachments.isEmpty()) {
            throw new ApplicationException(Label.METADATA_NOT_FOUND_COMPLIANCE);
        } else {
            System.debug('userStory: '+userStories[0]);
            System.debug('userStory Git Repository: '+userStories[0].Project__r.Deployment_Flow__r.Git_Repository__c);
            String url = copadoURL+'/json/v1/scanCompliance/';
            url += '?orgId='+orgId+'&userStoryId='+usId;
            if (userStories[0].Project__r.Deployment_Flow__r.Git_Repository__c != null) {
                url += '&repositoryId='+userStories[0].Project__r.Deployment_Flow__r.Git_Repository__c;
                url += '&branch=feature/' + userStories[0].Name;
            } else if (userStories[0].Release__r.Project__r.Deployment_Flow__r.Git_Repository__c != null) {
                url += '&repositoryId='+userStories[0].Release__r.Project__r.Deployment_Flow__r.Git_Repository__c;
                url += '&branch=feature/' + userStories[0].Name;
            }
            System.Debug('API callout = ' + url);
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            setAuthHeaders(req);//to authenticate agains heroku servers
            req.setEndpoint(url);
            req.setHeader('Content-Type' ,'application/json');
            req.setMethod('GET');

            HttpResponse res = h.send(req);
            HerokuResponse hr = new HerokuResponse(res);
            system.debug(req);
            system.debug(res.getBody());
            system.debug(hr);
        }
    }

    public static void retrieveVlocityDependencies(Id userStoryId, String jsonSelectedMetadata) {
        calloutForVlocityDependencies(userStoryId, jsonSelectedMetadata);
    }
    private static void calloutForVlocityDependencies(Id userStoryId, String jsonSelectedMetadata) {
        String url = copadoURL+'/json/v1/metadataDependencies?userStoryId=' + userStoryId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        setAuthHeaders(req);//to authenticate against heroku servers
        req.setEndpoint(url);
        req.setHeader('Content-Type' ,'application/json');
        req.setMethod('POST');
        req.setBody(jsonSelectedMetadata);

        HttpResponse res = h.send(req);
        String body = res.getBody();
        HerokuResponse hr = new HerokuResponse(res);

        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId,CopadoNotificationHelper.METADATA_DEPENDENCIES,userStoryId,'Starting...');
        }
    }
}