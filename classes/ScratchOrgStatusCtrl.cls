/**
 * Copado SFDX Delete Scratch Org Component's Controller
 * @author Jesus Gaviria
 * @see SfdxAPIHelper
 * @version 1.0
 * @since Copado v11
 */
public with sharing class ScratchOrgStatusCtrl extends ScratchOrgWizardPageBase {
    public Org__c soOrg { get; set; }
    public String soOrgId { get; set; }
    public String orgSelected {
        get {

            if ((orgSelected == null || orgSelected == '') && soOrgId != null) {
                orgSelected = soOrgId;
            }
            return orgSelected;
        }
        set;
    }
    public Boolean statusRetrieved { get; set; }
    public Boolean statusRequested { get; set; }
    public Datetime lastStatusCheck { get; set; }
    public Boolean copadoJobFinished { get; set; }
    private String cJobId = '';
    public String slockerMessage { get; set; }
    static final Integer RETRIES = 300;
    private Integer attemps = 0;
    public List<SelectOption> allScratchOrgs {
        get {
            if (allScratchOrgs == null) {
                List<SelectOption> sOrgsAux = new List<SelectOption>();
                allScratchOrgs = new List<SelectOption>();
                List<Org__c> sOrgs = SfdxAPIHelper.getOrgCredentials('Org_Type__c = \'Scratch Org\'');
                sOrgsAux.add(new selectOption('', 'Please Select a Scratch Org'));
                for (Org__c o : sOrgs) {
                    sOrgsAux.add(new selectOption(o.Id, o.Name));
                }
                allScratchOrgs = sOrgsAux;
            }
            return allScratchOrgs;
        }
        set;

    }

    public ScratchOrgStatusCtrl(ApexPages.StandardController std) {
    }

    public PageReference orgChanged() {
        lastStatusCheck = null;
        system.debug(soOrgId);
        system.debug(orgSelected);
        if (orgSelected != null && orgSelected != '') {
            soOrg = [
                    SELECT Id, Name, Org_Type__c, Scratch_Org_Expiration_Date__c, Developer_Hub_Org__c, Environment__c, is_Developer_Hub_Org__c, (select Id, LastModifiedDate from Attachments where Name = 'SourceStatus' ORDER BY lastmodifieddate DESC LIMIT 1)
                    FROM Org__c
                    WHERE Id = :orgSelected
            ];
            if (soOrg.Attachments.size() > 0) {
                lastStatusCheck = soOrg.Attachments[0].LastModifiedDate;
            }
        } else {
            soOrg = null;
        }
        return null;
    }

    private Id gitRepoId {
        get {
            if (gitRepoId == null) {
                system.debug(soOrg.Environment__c);
                list<Deployment_Flow_Step__c> dfs = [
                        SELECT Id, Deployment_Flow__r.Git_Repository__c
                        FROM Deployment_Flow_Step__c
                        WHERE Deployment_Flow__r.Git_Repository__c != null
                        AND Source_Environment__c = :soOrg.Environment__c
                ];
                system.debug(dfs);
                if (dfs.size() > 0) {
                    gitRepoId = dfs[0].Deployment_Flow__r.Git_Repository__c;
                }
            }
            return gitRepoId;
        }
        set;
    }

    public Boolean getHasRepo() {
        return (gitRepoId != null);
    }

    public Boolean getIsScratchOrg() {
        return (soOrg != null && soOrg.Org_Type__c != null && soOrg.Org_Type__c == 'Scratch Org');
    }
    public Boolean getIsActive() {
        return (getIsScratchOrg() && soOrg.Scratch_Org_Expiration_Date__c != null && soOrg.Scratch_Org_Expiration_Date__c > Datetime.now());
    }
    public ScratchOrgStatusCtrl() {
        statusRequested = false;
        statusRetrieved = false;
        orgSelected = soOrgId;
        cJobId = '';
        system.debug(orgSelected);
    }

    public PageReference requestStatus() {
        ApexPages.getMessages().clear();
        attemps = 0;
        statusRequested = true;
        statusRetrieved = false;
        copadoJobFinished = false;
        Copado_Notification__c cn = CopadoNotificationHelper.qInProgressCopadoNotification(CopadoNotificationHelper.DX_SOURCE_STATUS, soOrg.Id);
        system.debug(cn);
        if (cn != null) {
            cJobId = cn.Matching_Key__c;
        } else {
            cJobId = '';
        }
        return retrieveStatus();
    }

    public PageReference retrieveStatus() {

        PageReference pr = null;
        //Check if Id is correct and if user can open org
        try {
            if (cJobId == '' && soOrg.Id != null) {
                String s = SfdxAPI.sourceStatus(soOrgId,gitRepoId, SfdxAPIHelper.DX_PROJECT_BRANCH+String.valueOf(soOrg.Id).substring(3,15)); // AVOID FIRST 3 AND 3 LAST
                if (s != '') {
                    CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(s, CopadoNotificationHelper.copadoFrontAPIreponse.Class);
                    if (r.copadoJobId != null && r.copadoJobId != '') {
                        cJobId = r.copadoJobId;
                        copadoJobFinished = false;
                    } else if (r.error != null && r.error != '') {
                        copadoJobFinished = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, r.error));
                    }
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'No response'));
                }
            } else {
                Copado_Notification__c c = CopadoNotificationHelper.qCopadoNotificationBycopadoJobId(cJobId);
                if (c != null && c.isFinished__c != null && c.isFinished__c) {
                    if (c.isSuccess__c) {
                        copadoJobFinished = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Status Retrieved Succesfully'));
                        cJobId = '';
                    } else {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, c.Message__c));
                        copadoJobFinished = true;
                    }
                } else if(c != null){
                    slockerMessage = c.status__c;
                    copadoJobFinished = false;
                }

            }
        } catch (exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));
            copadoJobFinished = true;
        }
        return pr;
    }
}