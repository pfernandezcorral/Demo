/**
 * Compliance rule criteria management page.
 * List view like UX applied for users to adapt themselves easily
 * @author Mert YALTI
 * @version 1.0
 */
public with sharing class AddCCHRuleCriteriaExt {
    public String filterLogic {get; set;}
    public Boolean renderDetails {get; set;}
    public Boolean showFilterLogic {get; set;}
    public Boolean isValid {get; set;}
    public Boolean hasCriteria {get; set;}
    public String ruleCategoryType {get; set;}
    public List<SelectOption> categoryTypes {get; set;}
    public List<SelectOption> categoryNodes {get; set;}
    public Map<String, List<SelectOption>> nodeFields {get; set;}
    public Map<String, String> fieldTypes {get; set;}
    public List<CriteriaWrapper> criteriaList {get; set;}
    public Map<String, Categories> categoryMap {get; set;}
    public static List<SelectOption> operators {get; set;}
    public Compliance_Rule__c rule {get; private set;}
    private Map<Integer, CriteriaWrapper> validCriterias {get; set;}
    @TestVisible private Map<Integer, Compliance_Rule_Criteria__c> legacyCriterias {get; set;}
    @TestVisible private List<Compliance_Rule_Criteria__c> criteriaMemento {get; set;}
    public String logicMessage {get; set;}
    private Map<String, Nodes> selectedCategoryNodes {get; set;}
    @TestVisible private static String testValidationBody {get; set;}


    public AddCCHRuleCriteriaExt(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) stdController.addFields(new List<String>(Schema.SObjectType.Compliance_Rule__c.fields.getMap().keySet()));

        renderDetails = TRUE;
        if (!FeatureHelper.isComplianceHubEnabled()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.FEATURE_NOT_SUPPORTED));
            renderDetails = FALSE;
        } else if (!LicenseHelper.isCCHEnabled()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CCH_LICENSE_NOT_ENABLED));
            renderDetails = FALSE;
        } else if (!Test.isRunningTest() && (!Schema.SObjectType.Compliance_Rule__c.fields.Metadata_Type__c.isAccessible() ||
                    !Schema.SObjectType.Compliance_Rule__c.fields.Filter_Criteria__c.isAccessible() ||
                    !Schema.SObjectType.Compliance_Rule__c.fields.Is_Valid__c.isAccessible())) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.COMPLIANCE_RULE_MISSING_FLS));
            renderDetails = FALSE;
            this.rule = (Compliance_Rule__c)stdController.getRecord();
        } else {

            if (!Test.isRunningTest()) {
                stdController.addFields(new String[] {
                                            'Metadata_Type__c',
                                            'Filter_Criteria__c',
                                            'Is_Valid__c'
                                        });
            }
            this.rule = (Compliance_Rule__c)stdController.getRecord();

            criteriaMemento = new List<Compliance_Rule_Criteria__c>();

            isValid = rule.Is_Valid__c;

            ruleCategoryType = this.rule.Metadata_Type__c;

            categoryTypes = new List<SelectOption>();
            categoryTypes.add(new SelectOption('--None--', '--None--'));

            categoryNodes = new List<SelectOption>();
            categoryNodes.add(new SelectOption('--None--', '--None--'));

            nodeFields = new Map<String, List<SelectOption>>();
            List<SelectOption> temp = new List<SelectOption>();
            temp.add(new SelectOption('--None--', '--None--'));
            nodeFields.put('--None--', temp);

            setOperators();
            requestComplianceFile();

            criteriaList = new List<CriteriaWrapper>();

            legacyCriterias = new Map<Integer, Compliance_Rule_Criteria__c>();
            if (!String.isBlank(rule.Filter_Criteria__c) && rule.Filter_Criteria__c.contains('OR')) {
                filterLogic = rule.Filter_Criteria__c;
                showFilterLogic = true;
            } else {
                filterLogic = '';
                showFilterLogic = false;
            }
            hasCriteria = false;
            // If there are existing criterias associated with the rule following loop will prepare page variables against those criterias by doing following steps
            //  Will create CriteriaWrapper variables and fill them to the criteria list so that the page will display proper data
            //  Will convert filter criteria (RC-000123 AND RC-000124) to user readable filter logic (1 AND 2)
            setLegacyCriteria();
            // Will read compliance file that requested from backend and populate nodes list with select options
            /**
             * @see getNodePicklist();
             */
            if (!String.isBlank(ruleCategoryType)) {
                getNodePicklist();
            }

        }
    }
    private void setLegacyCriteria() {
        criteriaList.clear();
        legacyCriterias.clear();
        
        criteriaMemento.clear();

        for (Compliance_Rule_Criteria__c crc : [SELECT Id, Node__c, Field__c, Field_Type__c, Operator__c, Value__c, Name, Order__c, Compliance_Rule__c
                                                FROM Compliance_Rule_Criteria__c
                                                WHERE Compliance_Rule__c = : rule.Id
                                                        ORDER BY Order__c ASC]) {
            legacyCriterias.put(Integer.valueOf(crc.Order__c), crc);
            hasCriteria = true;
            String nodeName = !String.isBlank(crc.Node__c) ? crc.Node__c : '--None--';
            String fieldName = !String.isBlank(crc.Field__c) ? crc.Field__c : '--None--';
            String fieldType = !String.isBlank(crc.Field_Type__c) ? crc.Field_Type__c : 'STRING';

            String operator;
            if (crc.Operator__c != null && opetorsToCodes.containsKey(crc.Operator__c.toLowerCase())) {
                operator = opetorsToCodes.get(crc.Operator__c.toLowerCase());
            }
            String input = operator == 'w' || operator == 'x' ? crc.Value__c.substring(0, crc.Value__c.lastIndexOf(']')).replaceFirst('\\[', '') : crc.Value__c;
            List<SelectOption> temCriteriaOptions = new List<SelectOption>();
            if (type2ops.containsKey(fieldType.toUpperCase())) {
                for (String opt : type2ops.get(fieldType.toUpperCase())) {
                    if (operatorCodes.containsKey(opt)) {
                        temCriteriaOptions.add(new SelectOption(opt, operatorCodes.get(opt)));
                    }
                }
            }

            if (!String.isBlank(rule.Filter_Criteria__c) && crc.Order__c != null) {
                filterLogic = filterLogic.replace(crc.Name, String.valueOf(crc.Order__c));
                criteriaList.add(new CriteriaWrapper(nodeName, fieldName, fieldType, Integer.valueOf(crc.Order__c), operator, temCriteriaOptions, input));
            } else if (!String.isBlank(rule.Filter_Criteria__c) && crc.Order__c == null) {
                filterLogic = filterLogic.replace(crc.Name, 'NaN');
                criteriaMemento.add(crc);
                legacyCriterias.remove(Integer.valueOf(crc.Order__c));
            }
        }
        System.debug(LoggingLevel.INFO,'***legacyCriterias size:'+legacyCriterias.size());
        System.debug(LoggingLevel.INFO,'***criteriaList size:'+criteriaList.size());
        //When page is loaded if there is less than 3 existing criterias there will be (3 - existing criteria size) empty criteria display on the page
        //following loop creates those
        Integer pre = 3 - legacyCriterias.keySet().size() > 0 ? 3 - legacyCriterias.keySet().size() : 0;

        for (Integer i = 0; i < pre; i++) {
            System.debug(LoggingLevel.INFO,'***criteriaList size2:'+criteriaList.size());
            addNewCriteria();
        }
    }
    /**
     * Show or hide filter logic panel on the page
     * @return PageReference
     */
    public PageReference toggleLogic() {
        showFilterLogic = showFilterLogic == false;
        return null;
    }
    /**
     * Validates filter logic by creating an SOQL by using entered filter logic
     * If showFilterLogic is FALSE this method will be ignored during save
     * @return Boolean valid or not
     */
    public Boolean validateFilterLogic() {
        if (String.isEmpty(filterLogic)) {
            showFilterLogic = false;
            return true;
        }
        String[] items = filterLogic.toUpperCase().trim().split('AND|OR');
        
        
        
        
        if (items.size() < validCriterias.values().size()) {
            logicMessage = LABEL.CONDITION_DEFINED_BU_NOT_REF;
            return false;
        }

        String whereClause = filterLogic;
        Integer[] sortedItems = new List<Integer>();
        for (String i : items) {
            Integer order = Integer.valueOf(i.replace('(', '').replace(')', '').trim());
            sortedItems.add(order);
        }
        sortedItems.sort();
        for (Integer order = sortedItems.size(); order > 0; order--) {
            if (!validCriterias.containsKey(Integer.valueOf(order))) {
                logicMessage = LABEL.CONDITION_NOT_DEFINED_BUT_REF;
                return false;
                break;
            }
            System.debug('**f**whereClause : ' + whereClause);
            whereClause = whereClause.replace(String.valueOf(order), ' Name = \'test\'');
        }
        // This query may show SOQL injection security issue however that is actually false positive since we need to get where clause from UI in order to build the Compliance Rule.
        System.debug('**f**whereClause : ' + whereClause);
        String soqlString = 'SELECT Id FROM Compliance_Rule__c WHERE ' + String.valueOf(whereClause);
        System.debug('**f**soqlString : ' + soqlString);
        try {
            List<sObject> temp = database.query(soqlString);
            System.debug('**f**temp : ' + temp);
            return true;
        } catch (Exception e) {
            System.debug('**f**exception : ' + e.getMessage());
            logicMessage = LABEL.LOGIC_NOT_VALID + ' - ' + e.getMessage(); // For the next release make sure replacing e.getMessage() with a proper error handling algorith. Requested by Phil.
            return false;
        }
    }
    /**
     * Creates complete operators list
     * @see operatorCodes
     */
    private void setOperators() {
        if (operators == null) {
            operators = new List<SelectOption>();
            for (String oc : operatorCodes.keySet()) {
                operators.add(new SelectOption(oc , operatorCodes.get(oc)));
            }
        }
    }
    /**
     * Calls backend for compliance file which contains nodes, fields, field types JSON file
     * @return PageReference
     */
    public PageReference requestComplianceFile() {
        try {
            String callUrul = Settings.Server_URL + '/json/v1/complianceMetadata';
            HttpRequest req = new HttpRequest();
            req.setTimeout(30000);
            DeployAPI.setAuthHeaders(req);
            req.setHeader('Accept', 'application/json');
            req.setEndpoint(callUrul);
            req.setMethod('GET');
            Http h = new Http();
            HttpResponse res = h.send(req);
            String body = res.getBody();
            parseComplianceFile(body);

        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, LABEL.Connection_Problem));
        }
        return null;
    }
    /**
     * Parser method for compliance file that retrieved from backend
     * @param jsonStr Backend call Http response body
     */
    private void parseComplianceFile(String jsonStr) {

        List<Object> jsonObject = (List<Object>)JSON.deserializeUntyped(jsonStr);
        categoryMap = new Map<String, Categories>();

        for (Object o : jsonObject) {
            Categories cat = (Categories)JSON.deserialize(JSON.serialize(o), Categories.class);
            categoryTypes.add(new SelectOption(cat.categoryType, cat.categoryType));
            categoryMap.put(cat.categoryType, cat);
        }
        jsonObject.clear();
    }
    /**
     * Being invoked when a node is selected against a criteria on the page.
     * When a node other than none and name is selected other nodes are being disabled
     * because currently we can only support number of groups functionality
     *
     * Important Note: When we support Number of files and/or number of properties remove this function from here and from page
     */
    public void selectNode() {
        String selectedNode = '';
        for (CriteriaWrapper cw : criteriaList) {
            if (cw.nodeName != 'name' && cw.nodeName != '--None--') {
                if (String.isBlank(selectedNode)) {
                    selectedNode = cw.nodeName;
                }
            }
        }
        for (SelectOption n : categoryNodes) {
            if (!String.isBlank(selectedNode) && n.getValue() != selectedNode && n.getValue() != 'name' && n.getValue() != '--None--') {
                n.setDisabled(true);
            } else {
                n.setDisabled(false);
            }
        }
    }
    /**
     * Prepares node picklist values and fields list agains each node
     * @see requestComplianceFile
     */
    public void getNodePicklist() {
        if (categoryMap != null && rule.Metadata_Type__c != null && categoryMap.containsKey(rule.Metadata_Type__c)) {
            Categories selectedCat = categoryMap.get(rule.Metadata_Type__c);
            selectedCategoryNodes = new Map<String, Nodes>();
            for (Nodes n : selectedCat.nodes) {
                selectedCategoryNodes.put(n.name, n);
            }
            fieldTypes = new Map<String, String>();
            for (Nodes n : selectedCategoryNodes.values()) {
                categoryNodes.add(new SelectOption(n.metadataType, n.name));
                if (nodeFields.containsKey(n.metadataType)) {
                    List<SelectOption> temp = nodeFields.get(n.metadataType);
                    String[] fields = n.fields;
                    for (String f : fields) {
                        String[] fieldAndType = f.split(':');
                        temp.add(new SelectOption(fieldAndType[0], fieldAndType[0]));
                        nodeFields.put(n.metadataType, temp);
                        fieldTypes.put(fieldAndType[0], fieldAndType[1]);
                    }
                } else {
                    List<SelectOption> temp = new List<SelectOption>();
                    temp.add(new SelectOption('--None--', '--None--'));
                    String[] fields = n.fields;
                    for (String f : fields) {
                        String[] fieldAndType = f.split(':');
                        temp.add(new SelectOption(fieldAndType[0], fieldAndType[0]));
                        nodeFields.put(n.metadataType, temp);
                        fieldTypes.put(fieldAndType[0], fieldAndType[1]);
                    }
                }
            }
            if (criteriaList != null && !criteriaList.isEmpty()) {
                selectNode();
            }
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, 'Please select metadata type.'));
        }
    }
    /**
     * Dummy method for passing input values from page to controller
     * @see https://salesforce.stackexchange.com/questions/82590/input-values-are-not-set-in-controller for definition of the problem
     */
    public void dummy() {}

    /**
     * gets list of operators against a selected field by using its type
     */
    public void getFieldOperators() {
        String criteriaOrder = ApexPages.currentPage().getParameters().get('cro');
        if (!String.isBlank(criteriaOrder)) {
            Integer listOrder = Integer.valueOf(criteriaOrder) - 1;
            if (!criteriaList.isEmpty() && criteriaList.size() > listOrder) {
                CriteriaWrapper temp = criteriaList[listOrder];
                String criteriaField = temp.fieldName;
                if (fieldTypes.containsKey(criteriaField)) {
                    String fType = fieldTypes.get(criteriaField).toUpperCase();
                    temp.fieldType = fType;
                    List<SelectOption> criteriaOptions = new List<SelectOption>();
                    if (type2ops.containsKey(fType)) {
                        criteriaOptions.add(new SelectOption('--None--', '--None--'));
                        for (String opt : type2ops.get(fType)) {
                            if (operatorCodes.containsKey(opt)) {
                                criteriaOptions.add(new SelectOption(opt, operatorCodes.get(opt)));
                            }
                        }
                        temp.operatorSet = criteriaOptions;
                    } else {
                        for (String opt : type2ops.get('STRING')) {
                            if (operatorCodes.containsKey(opt)) {
                                criteriaOptions.add(new SelectOption(opt, operatorCodes.get(opt)));
                            }
                        }
                        temp.operatorSet = criteriaOptions;
                    }
                }
            }
        }
    }

    /**
     * To call validateRuleCallout from the VF page
     * ActionButtons requires methods that returns PageReference
     * @return PageReference
     */
    public PageReference validateRuleFromPage() {
        isValid = AddCCHRuleCriteriaExt.validateRuleCallout(rule);
        return null;
    }
    /**
     * Validate rule method that sends a call out to backend for the validation
     * @param  crule Compliance rule
     * @return       Boolean valid or not
     */
    public static Boolean validateRuleCallout(Compliance_Rule__c crule) {
        try {
            String callUrul = Settings.Server_URL + '/json/v1/validateComplianceRule/' + crule.Id;
            HttpRequest req = new HttpRequest();
            req.setTimeout(30000);
            DeployAPI.setAuthHeaders(req);
            req.setHeader('Accept', 'application/json');
            req.setEndpoint(callUrul);
            req.setMethod('GET');
            Http h = new Http();
            String body;
            if (!Test.isRunningTest()) {
                HttpResponse res = h.send(req);
                body = res.getBody();
            } else {
                body = AddCCHRuleCriteriaExt.testValidationBody;
            }
            Map<String, Object> ruleValidationResult = (Map<String, Object>)JSON.deserializeUntyped(body);
            if (ruleValidationResult.containsKey('error')) {
                String validationErrorMessage = (String)ruleValidationResult.get('error');
                crule.Is_Valid__c = FALSE;
                crule.Last_Validation_Status_Message__c = validationErrorMessage;
                crule.Last_Validation_Date_time__c = Datetime.now();
                Utilities.Secure_DML(crule, Utilities.DML_Action.UPD, schema.Sobjecttype.Compliance_Rule__c);
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, validationErrorMessage));
                return FALSE;
            } else {
                String validationSuccessMessage = (String)ruleValidationResult.get('ok');
                crule.Is_Valid__c = TRUE;
                crule.Last_Validation_Status_Message__c = validationSuccessMessage;
                crule.Last_Validation_Date_time__c = Datetime.now();
                Utilities.Secure_DML(crule, Utilities.DML_Action.UPD, schema.Sobjecttype.Compliance_Rule__c);
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, validationSuccessMessage));
                return TRUE;
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, LABEL.Connection_Problem));
        }

        return null;
    }
    /**
     * Save Operation
     * Saves valid criterias to be saved
     * Deletes removed criterias if they had been saved before
     * Validated criterias and filter logic
     * Translated user readable filter logic (1 AND 2) to backend readable logic (RC-000123 AND RC-000124)
     * @see validateCriterias
     * @see validateFilterLogic
     * @see SavePoint
     * @see Database.rollback()
     * @return PageReference new Compliance Rule view
     */
    public PageReference saveCriterias() {
        SavePoint sp = Database.setSavePoint();
        ApexPages.getMessages().clear();
        validCriterias = new Map<Integer, CriteriaWrapper>();
        validateCriterias();
        if (validCriterias.isEmpty()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, LABEL.AT_LEAST_ONE_VALID_CRITERIA));
            return null;
        }

        try {
            System.debug('**f**showFilterLogic : ' + showFilterLogic);
            if (showFilterLogic) {
                Boolean isLogicValid = validateFilterLogic();
                if (!isLogicValid) {
                    return null;
                }
            }
            logicMessage = null;

            Utilities.Secure_DML(criteriaMemento, Utilities.DML_Action.DEL, schema.Sobjecttype.Compliance_Rule_Criteria__c);
            hasCriteria = true;
            List<Compliance_Rule_Criteria__c> saveList = new List<Compliance_Rule_Criteria__c>();
            Set<String> existingCriteriaNames = new Set<String>();
            Integer j = 1;
            if (!showFilterLogic) {
                filterLogic = '';
            }
            System.debug(LoggingLevel.INFO,'***validCriterias :'+validCriterias.values().size());
            for (CriteriaWrapper cw : validCriterias.values()) {
                String formattedInput = cw.input;
                if (operatorCodes.get(cw.operator) == 'within' || operatorCodes.get(cw.operator) == 'excludes') {
                    formattedInput = '[' + formattedInput + ']';
                }
                String criteriaString = cw.nodeName + '.' + cw.fieldName + '<' + operatorCodes.get(cw.operator).deleteWhitespace().toUpperCase() + '>' + formattedInput;
                Compliance_Rule_Criteria__c temp;
                if (legacyCriterias.containsKey(cw.order) ) {
                    temp = legacyCriterias.get(cw.order);
                    if (existingCriteriaNames.contains(temp.Name)) {
                        continue;
                    }
                    existingCriteriaNames.add(temp.Name);
                } else {
                    temp = new Compliance_Rule_Criteria__c();
                }
                if (String.isBlank(temp.Compliance_Rule__c)) {
                    temp.Compliance_Rule__c = rule.Id;
                }
                temp.Criteria__c = criteriaString;
                temp.Order__c = j;
                temp.Node__c = cw.nodeName;
                temp.Field__c = cw.fieldName;
                temp.Field_Type__c = cw.fieldType;
                temp.Operator__c = operatorCodes.get(cw.operator).capitalize();
                temp.Value__c = formattedInput;

                saveList.add(temp);
                if (!showFilterLogic || (showFilterLogic && String.isBlank(filterLogic))) {
                    filterLogic += filterLogic != '' ? ' AND ' + j : String.valueOf(j);
                }
                j++;
            }
            System.debug(LoggingLevel.INFO,'***saveList :'+saveList);
            if (!saveList.isEmpty()) {
                Utilities.Secure_DML(saveList, Utilities.DML_Action.UPS, schema.Sobjecttype.Compliance_Rule_Criteria__c);

                Set<Id> savedIds = new Set<Id>();
                for (Compliance_Rule_Criteria__c scrc : saveList) {
                    savedIds.add(scrc.Id);
                }
                Map<Integer, String> mergeitems = new Map<Integer, String>();
                Map<String, String> itemNames = new Map<String, String>();
                String[] splitLogic = filterLogic.toUpperCase().trim().split('AND|OR');

                Integer[] sortedItems = new List<Integer>();
                for (String i : splitLogic) {
                    Integer item = Integer.valueOf(i.replace('(', '').replace(')', '').trim());
                    sortedItems.add(item);
                }
                sortedItems.sort();

                for (Integer i : sortedItems) {
                    mergeitems.put(i, '{' + i + '}');
                }
                for (Compliance_Rule_Criteria__c crc : [SELECT Id, Name, Order__c FROM Compliance_Rule_Criteria__c WHERE Id IN: savedIds]) {
                    if (mergeitems.containsKey(Integer.valueOf(crc.Order__c))) {
                        itemNames.put('{' + crc.Order__c + '}', crc.Name);
                    }
                }
                for (Integer i = sortedItems.size(); i > 0; i-- ) {
                    String mergeVal = mergeitems.get(i);
                    if (mergeVal != null) {
                        filterLogic = filterLogic.replace(String.valueOf(i), mergeVal).replace('}}', '}').replace('{{', '{').replace('}{', '').replace('}0', '0');
                    }
                }

                for (Integer i = sortedItems.size(); i > 0; i-- ) {
                    String mergeVal = mergeitems.get(i);
                    if (mergeVal != null && itemNames.containsKey(mergeVal)) {
                        filterLogic = filterLogic.replace(mergeVal, itemNames.get(mergeVal));
                    }
                }

                rule.Filter_Criteria__c = filterLogic;
                if(Schema.getGlobalDescribe().get(Settings.ns+'Compliance_Rule__c').getDescribe().isAccessible()) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Compliance Rule object is not accessible'));
                    return null;
                }
                Compliance_Rule__c resetState = [SELECT Is_Valid__c, Last_Validation_Status_Message__c, Last_Validation_Date_time__c FROM Compliance_Rule__c WHERE Id = : rule.Id LIMIT 1];
                rule.Is_Valid__c = resetState.Is_Valid__c;
                rule.Last_Validation_Status_Message__c = resetState.Last_Validation_Status_Message__c;
                rule.Last_Validation_Date_time__c = resetState.Last_Validation_Date_time__c;
                isValid = resetState.Is_Valid__c;
                Utilities.Secure_DML(rule, Utilities.DML_Action.UPD, schema.Sobjecttype.Compliance_Rule__c);
                setLegacyCriteria();
                return null;
            }
        } catch (Exception e) {
            
            Database.rollBack(sp);
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
        return null;
    }
    /**
     * In order to insert a criteria, it requires a node, a field and an operator so this methods check criterias against this rule
     */
    public void validateCriterias() {
        
        Integer i = 0;
        System.debug(LoggingLevel.INFO,'***validateCriterias criteriaList:'+criteriaList);
        for (CriteriaWrapper cw : criteriaList) {
            i++;

            if (!String.isBlank(cw.nodeName) && cw.nodeName != '--None--' && !String.isBlank(cw.fieldName) && cw.fieldName != '--None--' && !String.isBlank(cw.operator) && cw.operator != '--None--') {
                validCriterias.put(i, cw);
            } else if (legacyCriterias.containsKey(i) && !showFilterLogic) {
                criteriaMemento.add(legacyCriterias.get(i));
                legacyCriterias.remove(i);
            }
        }
        System.debug(LoggingLevel.INFO,'***criteriaMemento :'+criteriaMemento);
    }
    /**
     * Cancels operation and navigates page back to rule detail view
     * @return PageReference new Compliance Rule view
     */
    public PageReference cancelCriterias() {
        return new ApexPages.StandardController(rule).view();
    }
    /**
     * Creates new criteria place holder
     * @see CriteriaWrapper
     * @return PageReference
     */
    public PageReference addNewCriteria() {
        if (criteriaList != null) {
            CriteriaWrapper temp = new CriteriaWrapper();
            setOperators();
            temp.operatorSet = operators;
            temp.order = criteriaList.size() + 1;
            criteriaList.add(temp);
        }
        return null;
    }
    /**
     * Removes criteria from criteria list and also if the criteria has already inserted adds it to criteria memento list to delete during save
     * @see CriteriaWrapper
     * @return PageReference
     */
    public PageReference removeCriteria() {
        System.debug(LoggingLevel.INFO,'***removeCriteria:::criteriaList :'+criteriaList.size());
        System.debug(LoggingLevel.INFO,'***removeCriteria:::criteriaMemento :'+criteriaMemento.size());
        if (criteriaList != null && criteriaList.size() > 0) {

            if (legacyCriterias.containsKey(criteriaList.size())) {
                criteriaMemento.add(legacyCriterias.get(criteriaList.size()));
                legacyCriterias.remove(criteriaList.size());
            }
            criteriaList.remove(criteriaList.size() - 1);
        }
        System.debug(LoggingLevel.INFO,'***removeCriteria:::criteriaList later :'+criteriaList.size());
        System.debug(LoggingLevel.INFO,'***removeCriteria:::criteriaMemento later :'+criteriaMemento.size());
        return null;
    }

    /**
     * Code to operator map
     */
    private Map<String, String> operatorCodes = new Map<String, String> {
        '' => '--None--',
        'e' => 'equals',
        'n' => 'not equal to',
        's' => 'starts with',
        'c' => 'contains',
        'k' => 'does not contain',
        'l' => 'less than',
        'g' => 'greater than',
        'm' => 'less or equal',
        'h' => 'greater or equal',
        'u' => 'includes',
        'x' => 'excludes',
        'w' => 'within'
    };
    /**
     * operator to code map
     */
    private Map<String, String> opetorsToCodes = new Map<String, String> {
        'equals' => 'e',
        'not equal to' => 'n',
        'starts with' => 's',
        'contains' => 'c',
        'does not contain' => 'k',
        'less than' => 'l',
        'greater than' => 'g',
        'less or equal' => 'm',
        'greater or equal' => 'h',
        'includes' => 'u',
        'excludes' => 'x',
        'within' => 'w'
    };
    /**
     * Field types agains possible operator codes
     */
    private Map<String, String[]> type2ops = new Map<String, String[]> {
        'ANYTYPE' => new String[]{'e', 'n', 's', 'c', 'k', 'l', 'g', 'm', 'n', 'h', 'u', 'x', 'w'},
        'BASE64BINARY' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'BOOLEAN' => new String[]{'e', 'n'},
        'DATE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
        'DATETIME' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
        'DOUBLE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
        'ID' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'INTEGER' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
        'INT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
        'STRING' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i', 'w', 'x'},
        'TIME' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
        'ADDRESS' => new String[]{'w', 'y'},
        'ADDRESSCOUNTRY' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'ADDRESSSTATE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'AUTONUMBER' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'BIRTHDAY' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
        'BITVECTOR' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'CONTENT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'CURRENCY' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
        'CURRENCYCODE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'DATACATEGORYGROUPREFERENCE' => new String[]{'e', 'n'},
        'DATEONLY' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
        'DIVISION' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'DUEDATE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
        'DYNAMICENUM' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'EMAIL' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'ENCRYPTEDTEXT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'ENTITYID' => new String[]{'e', 'n', 's'},
        'ENUMORID' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'EXTERNALID' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'FAX' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'HTMLMULTILINETEXT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'HTMLSTRINGPLUSCLOB' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'INETADDRESS' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'LOCATION' => new String[]{'w', 'y'},
        'MULTIENUM' => new String[]{'e', 'n', 'u', 'x'},
        'MULTILINETEXT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'PERCENT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
        'PHONE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'RECORDTYPE' => new String[]{'e', 'n'},
        'SFDCENCRYPTEDTEXT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'SIMPLENAMESPACE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'STATICENUM' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'STRINGPLUSCLOB' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'TEXT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'TEXTENUM' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
        'TIMEONLY' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
        'URL' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'}
    };
    /**
     * Wrapper object to parse Compliance file easily
     */
    public class Categories {
        public String categoryType {get; set;}
        public List<Nodes> nodes {get; set;}
    }
    /**
     * Wrapper object to parse Compliance file easily
     */
    public class Nodes {
        public String name {get; set;}
        public String metadataType {get; set;}
        public String metadataNameField {get; set;}
        public String[] fields {get; set;}
    }
    /**
     * Criteria wrapper class
     */
    public class CriteriaWrapper {
        public String nodeName {get; set;}
        public String fieldName {get; set;}
        public String fieldType {get; set;}
        public Integer order {get; set;}
        public String operator {get; set;}
        public List<SelectOption> operatorSet {get; set;}
        public String input {get; set;}

        public CriteriaWrapper(String nodeName, String fieldName, String fieldType, Integer order, String operator, List<SelectOption> operatorSet, String input) {
            this.nodeName = nodeName;
            this.fieldName = fieldName;
            this.fieldType = fieldType;
            this.order = order;
            this.operator = operator;
            this.operatorSet = operatorSet;
            this.input = input;
        }

        public CriteriaWrapper() {
            this.nodeName = '--None--';
            this.fieldName = '--None--';
            this.fieldType = 'STRING';
            this.operator = '--None--';
            this.operatorSet = new List<SelectOption>();
            this.input = '';
        }
    }
}