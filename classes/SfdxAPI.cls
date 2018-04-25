/**
 * Copado SFDX client api. In this class salesforce dx related callout and common operation methods are being handled.
 * Salesforce DX is an open and standard developer experience, letting you build with the tools you love including Git, Selenium, Eclipse, Sublime, and more.
 * Salesforce DX includes an updated Eclipse integrated development environment (IDE) that significantly expands the value of the toolset to developers.
 * With Copado's DX solution everybody, even someone who doesn't know CLI can use most of DX features.
 * @author Mert YALTI
 * @author Jesus Gaviria
 * @see SfdxAPIHelper
 * @version 1.0
 * @since Copado v11
 */
public with sharing class SfdxAPI extends SfdxAPIHelper {
    public static String convertIgnore {get;set;}
    public static String pushIgnore {get;set;}
    /**
     * SFDX Scratch Org creation call out.
     * @author Mert YALTI
     * @param  orgDefinitionJSON JSON file which defines scratch org structure. The scratch org definition file is a blueprint for a scratch org. It mimics the shape of an org that you use in the development life cycle, such as org type, edition, features etc.
     * @param  devHubOrgId       Hub org Id. The Developer Hub (Dev Hub) lets you create and manage scratch orgs. The scratch org is a source-driven and disposable deployment of Salesforce code and metadata, made for developers and automation.
     * @param  copadoDxOrgId     Copado org credential Id which will contain information about the scratch org that will be created. Backend will update this org credential with scratch org details when the scratch org is created.
     * @param  durationDays      duration of the scratch org(in days) (default:7, min:1,max:30)
     * @see HttpRequest
     * @see HttpResponse
     * @return HttpResponse body
     */
    public static void orgCreate(String orgDefinitionJSON, String devHubOrgId, String orgName, Integer durationDays, String flowId, String targetEnv, String usId) {
        durationDays = durationDays == null || durationDays == 0 ? 7 : durationDays;
        String callURL = Settings.Server_URL + '/json/v1/dx/scratchOrg?devHubOrgId=' + EncodingUtil.urlEncode(devHubOrgId,'UTF-8') + '&orgName=' + EncodingUtil.urlEncode(orgName,'UTF-8') + '&durationDays=' + durationDays;
        if(String.isNotBlank(flowId) && flowId != '-- None --'){
            callURL += '&flowId=' + EncodingUtil.urlEncode(flowId,'UTF-8');
            if(String.isNotBlank(targetEnv) && targetEnv != '-- None --'){
                callURL += '&targetEnv=' + EncodingUtil.urlEncode(targetEnv,'UTF-8');
            }/*jg: not required! else {
                throw new CopadoDxException('Target Environment needs to be defined when deployment flow step creation requested.');
            }*/
        }
        if(String.isNotBlank(usId)){
            callURL += '&userStoryId=' + EncodingUtil.urlEncode(usId,'UTF-8');
        }
        Map<String,String> attachments = new Map<String,String>();
        attachments.put(SfdxAPIHelper.DX_DEFINITION_FILE,orgDefinitionJSON);
        System.debug('**f**callURL : ' + callURL);
        System.debug('**f**attachments : ' + attachments);
        try{
            HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, JSON.serialize(attachments), true);
            String body = res.getBody();
            System.debug(loggingLevel.INFO, '*** org_create body: ' + body);
            if(String.isNotBlank(body)){
                CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
                if(String.isNotBlank(r.copadoJobId)) {
                    JobsManager.createRunningJob(r.CopadoJobId,CopadoNotificationHelper.DX_CREATE_ORG,null,'Starting...');
                }
            }
        }
        catch (Exception e){
            throw new CopadoDxException('An error has been occurred during org creation.' + e.getMessage());
        }

        //return body;
    }
    /**
     * Open an org any org
     * sfdx force:org:open
     * -p, --path PATH navigation URL path
     * -u, --targetusername TARGETUSERNAME  username or alias for the target org; overrides default target org display navigation URL, but don’t launch browser
     * Scratch org information will be encrypted in an attachment on org credentials callURL
     * Regular orgs like sandbox, dev org, prod will be accessible via oAuth token and user name
     * @param username Scratch org user name
     * @param copadoDxOrgId username for the dev hub org
     * @return HttpResponse body
     */
    public static String orgOpen(String orgId) {
        if (String.isEmpty(orgId)) {
            throw new CopadoDxException(Label.Org_Open_OrgId_Required);
            return null;
        }
        String callURL = Settings.Server_URL + '/json/v1/org/' + EncodingUtil.urlEncode(orgId,'UTF-8') + '/accessUrl';
        HttpResponse res = SfdxAPIHelper.callDxJob('GET', callURL, null, false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** org_open body: ' + body);
        return body;
    }
	public static String loadMetadataFromGit(String projectJSON, String mdSourcesJSON, String scratchOrgId, String repoId, String branchName, String dxRepositoryId, String sendEmail, Boolean convertSource) {
		if(String.isEmpty(scratchOrgId)){
            throw new CopadoDxException(Label.Load_MD_OrgId_Required);
			return null;
		}

        Map<String,String> attachments = new Map<String,String>();
        if(String.isNotBlank(projectJSON)) attachments.put(SfdxAPIHelper.DX_PROJECT_FILE,SfdxAPIHelper.orgDefinitionDefaultKeyFixer(projectJSON));
        if(String.isNotBlank(mdSourcesJson)) attachments.put(SfdxAPIHelper.DX_METADATA_SOURCES,mdSourcesJson);

		String callURL = Settings.Server_URL + '/json/v1/dx/scratchOrg/'+scratchOrgId+'/metadata?repositoryId='+repoId+'&dxRepositoryId='+dxRepositoryId+'&sendEmail=true&convertSource='+convertSource;
		if(String.isNotBlank(dxRepositoryId)){
            callURL += '&branch='+EncodingUtil.urlEncode(branchName,'UTF-8');
        }
        HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, JSON.serialize(attachments), false);
        String body = res.getBody();
		System.debug(loggingLevel.INFO, '*** org_open body: ' + body);
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId,CopadoNotificationHelper.DX_LOAD_METADATA,null,'Starting...');
        }
		return body;
	}
    public static String loadMetadataFromOrg(String projectJSON, String mdSourcesJSON, String scratchOrgId, String orgId, String dxRepositoryId) {
        if(String.isEmpty(scratchOrgId)){
            throw new CopadoDxException(Label.Load_MD_OrgId_Required);
            return null;
        }

        Map<String,String> attachments = new Map<String,String>();
        if(String.isNotBlank(projectJSON)) attachments.put(SfdxAPIHelper.DX_PROJECT_FILE,SfdxAPIHelper.orgDefinitionDefaultKeyFixer(projectJSON));
        if(String.isNotBlank(mdSourcesJson)) attachments.put(SfdxAPIHelper.DX_METADATA_SOURCES,mdSourcesJson);
        if(String.isNotBlank(SfdxAPI.convertIgnore)) attachments.put(SfdxAPIHelper.DX_CONVERT_IGNORE,SfdxAPI.convertIgnore);
        if(String.isNotBlank(SfdxAPI.pushIgnore)) attachments.put(SfdxAPIHelper.DX_PUSH_IGNORE,SfdxAPI.pushIgnore);

        String callURL = Settings.Server_URL + '/json/v1/dx/scratchOrg/'+EncodingUtil.urlEncode(scratchOrgId,'UTF-8')+'/metadata?orgId='+EncodingUtil.urlEncode(orgId,'UTF-8');
        if(String.isNotBlank(dxRepositoryId)){
            callURL += '&dxRepositoryId='+EncodingUtil.urlEncode(dxRepositoryId,'UTF-8');
        }
        HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, JSON.serialize(attachments), false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** org_open body: ' + body);
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId,CopadoNotificationHelper.DX_LOAD_METADATA,null,'Starting...');
        }
        return body;
    }
    public static String loadMetadataFromArtifacts(String projectJSON, String mdSourcesJSON, String scratchOrgId, String dxRepositoryId, String sendEmail) { // artifacts will be comma separated
        if(String.isEmpty(scratchOrgId)){
            throw new CopadoDxException(Label.Load_MD_OrgId_Required);
            return null;
        }

        Map<String,String> attachments = new Map<String,String>();
        if(String.isNotBlank(projectJSON)) attachments.put(SfdxAPIHelper.DX_PROJECT_FILE,SfdxAPIHelper.orgDefinitionDefaultKeyFixer(projectJSON));
        if(String.isNotBlank(mdSourcesJson)) attachments.put(SfdxAPIHelper.DX_METADATA_SOURCES,mdSourcesJson);

        String callURL = Settings.Server_URL + '/json/v1/dx/scratchOrg/'+EncodingUtil.urlEncode(scratchOrgId,'UTF-8')+'/metadata?sendEmail=true';
        if(String.isNotBlank(dxRepositoryId)){
            callURL += '&dxRepositoryId='+EncodingUtil.urlEncode(dxRepositoryId,'UTF-8');
        }
        System.debug('**f**callURL : ' + callURL);
        HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, JSON.serialize(attachments), false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** org_open body: ' + body);

        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId,CopadoNotificationHelper.DX_LOAD_METADATA,null,'Starting...');
        }
        return body;
    }


    /**
     * List all DX orgs you’ve created or authenticated to
     * sfdx force:org:list
     * Flags:
     * -p, --noprompt       do not prompt for confirmation
     * --all                include expired, deleted, and unknown-status scratch orgs
     * --clean              remove all local org authorizations for non-active orgs
     * @param copadoDxOrgId username for the dev hub org
     * @param getAll include expired, deleted, and unknown-status scratch orgs
     * @param clean remove all local org authorizations for non-active orgs
     * @return HttpResponse body
     */
    public static String orgList(String copadoDxOrgId, Boolean getAll, Boolean clean) {
        if (String.isEmpty(copadoDxOrgId)) {
            throw new CopadoDxException(Label.List_Orgs_OrgId_Required);
            return null;
        }
        String callURL = Settings.Server_URL + '/json/v1/dx/[GetOrgListEndPoint]?copadoDxOrgId='+EncodingUtil.urlEncode(copadoDxOrgId,'UTF-8')+'&all='+getAll+'&clean='+clean;
        HttpResponse res = SfdxAPIHelper.callDxJob('GET', callURL, null, false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** org_list body: ' + body);
        return body;
    }

    /**
     * Mark a scratch org for deletion
     * sfdx force:org:delete
     * Flags:
     *  -p, --noprompt => no prompt to confirm deletion (Will be used all the time by the backend since confirmation will be handled by UI)
     *  -v, --targetdevhubusername TARGETDEVHUBUSERNAME username or alias for the dev hub org; overrides default dev hub org
     *  -u, --targetusername TARGETUSERNAME (required) username or alias for the target org
     * Sanity check is required before killing an org
     * source_status should be triggered to display changed metadata
     * And also related user stories, scheduled permissions where scratch org is source etc should be displayed
     * @param username Scratch org user name
     * @return HttpResponse body
     */
    public static String orgDelete(String scratchOrgId) {
        if (String.isEmpty(scratchOrgId)) {
            throw new CopadoDxException(Label.Org_Delete_OrgId_Required);
            return null;
        }
        String callURL = Settings.Server_URL + '/json/v1/dx/scratchOrg/'+EncodingUtil.urlEncode(scratchOrgId,'UTF-8');
        HttpResponse res = SfdxAPIHelper.callDxJob('DELETE', callURL, null, false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** org_delete body: ' + body);
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId,CopadoNotificationHelper.DX_DELETE_ORG,null,'Starting...');
        }
        return body;
    }
    /**
     * get org description
     * Output includes your access token, client ID, connected status, org ID, instance URL, username, and alias, if applicable.
     * Use --verbose to include the SFDX auth URL. (We dont need this for Copado UI, but customers may need it)
     * @param username Scratch org user name
     * @return HttpResponse body
     */
    public static String orgDisplay(String scratchOrgId) {
        if (String.isEmpty(scratchOrgId)) {
            throw new CopadoDxException(Label.Org_Display_Username_Required);
            return null;
        }
        String callURL = Settings.Server_URL + '/json/v1/dx/scratchOrg/'+EncodingUtil.urlEncode(scratchOrgId,'UTF-8')+'/orgDetails';
        HttpResponse res = SfdxAPIHelper.callDxJob('GET', callURL, null, false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** org_display body: ' + body);
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId,CopadoNotificationHelper.DX_ORG_DETAILS,null,'Starting...');
        }
        return body;
    }

    public static String generatePassword(String scratchOrgId) {
        if (String.isEmpty(scratchOrgId)) {
            throw new CopadoDxException(Label.Org_Display_Username_Required);
            return null;
        }
        String callURL = Settings.Server_URL + '/json/v1/dx/scratchOrg/'+EncodingUtil.urlEncode(scratchOrgId,'UTF-8')+'/ideDetails';
        HttpResponse res = SfdxAPIHelper.callDxJob('GET', callURL, null, false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** generatePassword body: ' + body);
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId,CopadoNotificationHelper.DX_ORG_IDE_DETAILS,null,'Starting...');
        }
        return body;
    }

    /**
     * list changes in a scratch org
     * sfdx force:source:status
     * -a, --all list all the changes that have been made (Will not be used in Copado)
     * -l, --local list the changes that have been made locally (Will not be used in Copado)
     * -r, --remote list the changes that have been made in the scratch org (AuditTrail)
     * -u, --targetusername TARGETUSERNAME  username or alias for the target org;
     * @param username Scratch org user name
     * @return HttpResponse body
     */
    public static String sourceStatus(String scratchOrgId, String repositoryId, String branch) {
        if (String.isEmpty(scratchOrgId)) {
            throw new CopadoDxException(Label.Org_Status_OrgId_Required);
            return null;
        }
        String callURL = Settings.Server_URL + '/json/v1/dx/scratchOrg/' + EncodingUtil.urlEncode(scratchOrgId,'UTF-8') + '/sourceStatus?repositoryId=' + EncodingUtil.urlEncode(repositoryId,'UTF-8') + '&branch=' + EncodingUtil.urlEncode(branch,'UTF-8');
        System.debug(loggingLevel.INFO, '*** callURL body: ' + callURL);
        HttpResponse res = SfdxAPIHelper.callDxJob('GET', callURL, null, false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** source_status body: ' + body);
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId,CopadoNotificationHelper.DX_SOURCE_STATUS,null,'Starting...');
        }
        return body;
    }

    public static void fullScratchOrg(String definitionJSON, String devHubOrgId, String orgName, Integer durationDays, String flowId, String targetEnv, String artifactIds, String sourceOrgId, String sourceBranch, String permSets, String projectJSON, String mdSourcesJson,String dxRepositoryId,String usId, String convertSource) {
        String metadataSourceParameters = '';
        if (String.isNotBlank(artifactIds)) {
            metadataSourceParameters = '&artifactIds=' + EncodingUtil.urlEncode(artifactIds.replace('[','').replace(']',''),'UTF-8');
        } else if (String.isNotBlank(sourceOrgId)) {
            metadataSourceParameters = '&orgId=' + EncodingUtil.urlEncode(sourceOrgId,'UTF-8');
        } else if (String.isNotBlank(sourceBranch)) {
            metadataSourceParameters = '&branch=' + EncodingUtil.urlEncode(sourceBranch,'UTF-8');
        }

        if(String.isNotBlank(dxRepositoryId)){
            metadataSourceParameters = metadataSourceParameters+ '&dxRepositoryId=' + EncodingUtil.urlEncode(dxRepositoryId,'UTF-8');
        }
        if(String.isNotBlank(usId)){
            metadataSourceParameters = metadataSourceParameters+ '&userStoryId=' + EncodingUtil.urlEncode(usId,'UTF-8');
        }
        if(String.isNotBlank(permSets)){
            metadataSourceParameters = metadataSourceParameters+ '&permSets=' + EncodingUtil.urlEncode(permSets,'UTF-8');
        }

        //metadataSourceParameters = '&branch=master&repositoryId=a0Q0Y00000FsuDW&dxRepositoryId=a0Q0Y00000FsuDW';
        String callURL = Settings.Server_URL + '/json/v1/dx/fullScratchOrg/?devHubOrgId=' + EncodingUtil.urlEncode(devHubOrgId,'UTF-8') + '&sendEmail=true' + '&durationDays=' + durationDays+'&orgName='+EncodingUtil.urlEncode(orgName,'UTF-8')+'&convertSource='+convertSource;
        if (String.isNotBlank(metadataSourceParameters)) {
            callURL += metadataSourceParameters;
        }
        if(String.isNotBlank(flowId) && flowId != '-- None --'){
            callURL += '&flowId='+EncodingUtil.urlEncode(flowId,'UTF-8');
            if(String.isNotBlank(targetEnv) && targetEnv != '-- None --'){
                callURL += '&targetEnv='+EncodingUtil.urlEncode(targetEnv,'UTF-8');
            } /*else {
                throw new CopadoDxException('Target Environment needs to be defined when deployment flow step creation requested.');
            }*/
        }
        Map<String,String> attachments = new Map<String,String>();
        if(String.isNotBlank(definitionJSON))attachments.put(SfdxAPIHelper.DX_DEFINITION_FILE,definitionJSON);
        else throw new CopadoDxException('Scratch Org Definition is required');

        if(String.isNotBlank(projectJSON)) attachments.put(SfdxAPIHelper.DX_PROJECT_FILE,SfdxAPIHelper.orgDefinitionDefaultKeyFixer(projectJSON));
        if(String.isNotBlank(mdSourcesJson)) attachments.put(SfdxAPIHelper.DX_METADATA_SOURCES,mdSourcesJson);

        System.debug(loggingLevel.INFO, '*** callURL: ' + callURL);
        System.debug(LoggingLevel.INFO,'***JSON.serialize(attachments) :'+JSON.serialize(attachments));
        HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, JSON.serialize(attachments), true);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** fullScratchOrg body: ' + body);
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId,'DxCreateFullScratchOrgJob',null,'Starting...');
        }
    }
    @Future(callout=true)
    public static void refreshStatus() {
        String callURL = Settings.Server_URL + '/json/v1/dx/scratchOrgsStatus';
        HttpResponse res = SfdxAPIHelper.callDxJob('GET', callURL, null, false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** source_pull body: ' + body);
    }
    public static String scratchOrgPermissionSets(String scratchOrgId, String permSets){//permSets: CSV string
        if (String.isEmpty(scratchOrgId)) {
            throw new CopadoDxException(Label.Org_PermissionSet_Username_Required);
            return null;
        }
        String callURL = Settings.Server_URL + '/json/v1/dx/scratchOrg/' + EncodingUtil.urlEncode(scratchOrgId,'UTF-8') + '/permissionSets?scratchOrgId=' + EncodingUtil.urlEncode(scratchOrgId,'UTF-8') + '&permSets=' + EncodingUtil.urlEncode(permSets,'UTF-8');
        System.debug(loggingLevel.INFO, '*** callURL body: ' + callURL);
        HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, null, false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** source_status body: ' + body);
        return body;
    }

    public static String retrieveBranchesFromRepository(String repoId) {
        if (String.isEmpty(repoId)) {
            throw new CopadoDxException(Label.RepoId_Required);
            return null;
        }
        repoId = repoId != null ? repoId : '';
        String callURL = Settings.Server_URL + '/json/v1/dx/gitBranches/' + EncodingUtil.urlEncode(repoId, 'UTF-8');
        HttpResponse res = SfdxAPIHelper.callDxJob('GET', callURL, null, false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** source_pull body: ' + body);
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId,'DxListRepositoryBranches',null,'Starting...');
        }
        return body;
    }
    public static String artifactSnapshot(String artifactId) {
        if (String.isEmpty(artifactId)) {
            throw new CopadoDxException(Label.ArtifactId_Required);
            return null;
        }
        //repoId = repoId != null ? repoId : '';
        String callURL = Settings.Server_URL + '/json/v1/dx/artifactSnapshot/' + EncodingUtil.urlEncode(artifactId,'UTF-8');
        HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, null, false);
        String body = res.getBody();
        System.debug(loggingLevel.INFO, '*** source_pull body: ' + body);
        return body;
    }

    public static void getListOfPackages(String orgId){
        String callURL = Settings.Server_URL+'/json/v1/dx/packagesList/'+EncodingUtil.urlEncode(orgId,'UTF-8');
        HttpResponse res = SfdxAPIHelper.callDxJob('GET', callURL, null, false);
        String body = res.getBody();
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId,'DxListOrgPackagesJob',null,'Starting...');
        }
    }

    public static void mergeReleases(String artifactId, String releaseId){
        String callURL = Settings.Server_URL+'/json/v1/dx/artifact/' + artifactId +  '/mergeRelease?releaseId=' + releaseId;
        HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, null, false);
        String body = res.getBody();
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId,CopadoNotificationHelper.DX_ARTIFACT_MERGE_RELEASE,null,'Starting...');
        }
    }

    public static void createProjectBranch(String orgId,String dxRepoId){
        if (String.isEmpty(orgId)) {
            throw new CopadoDxException('Scratch Org Id is required');
            return;
        } else if (String.isEmpty(dxRepoId)) {
            throw new CopadoDxException('Repository Id where Project branch will be created is required.');
            return;
        }
        String callURL = Settings.Server_URL+'/json/v1/dx/scratchOrg/'+orgId+'/projectBranch?dxRepositoryId='+dxRepoId;
        HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, null, false);
        String body = res.getBody();
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
        if(String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.CopadoJobId,CopadoNotificationHelper.DX_CREATE_PROJECT_BRANCH,null,'Starting...');
        }
    }

    public class CopadoDxException extends Exception{}

    public SfdxAPI() {
    }

}