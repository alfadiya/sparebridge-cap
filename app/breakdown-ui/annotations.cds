using SpareBridgeService as service from '../../srv/sparebridge-service';

annotate service.BreakdownRequests with @(

    // --- Page title shown on the Object Page (detail screen) ---
    UI.HeaderInfo : {
        TypeName       : 'Breakdown Request',
        TypeNamePlural : 'Breakdown Requests',
        Title          : { Value : ID },
        Description    : { Value : material }
    },

    // --- Buttons shown on the DETAIL page toolbar ---
    UI.Identification : [
        {
            $Type  : 'UI.DataFieldForAction',
            Label  : 'Find Matches',
            Action : 'SpareBridgeService.BreakdownRequests/findMatches',
        },
    ],

    // --- Columns shown in the LIST page table ---
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Label : 'Request ID',
            Value : ID,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Plant',
            Value : plant.name,       // shows "IOCL Panipat Refinery" instead of "P001"
        },
        {
            $Type : 'UI.DataField',
            Label : 'Material',
            Value : material,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Quantity Needed',
            Value : quantity,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Urgency (1-5)',
            Value : urgency,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Status',
            Value : status,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Fulfilled',
            Value : fulfilledQty,
        },
    ],

    // --- Fields shown on the DETAIL page (Object Page) ---
    UI.FieldGroup #GeneralInfo : {
        $Type : 'UI.FieldGroupType',
        Data : [
            {
                $Type : 'UI.DataField',
                Label : 'Request ID',
                Value : ID,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Plant',
                Value : plant.name,
            },
            {
                $Type : 'UI.DataField',
                Label : 'City',
                Value : plant.city,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Material',
                Value : material,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Quantity Needed',
                Value : quantity,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Urgency (1=Low, 5=Critical)',
                Value : urgency,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Status',
                Value : status,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Fulfilled Quantity',
                Value : fulfilledQty,
            },
        ],
    },

    // --- Sections shown on the DETAIL page ---
    UI.Facets : [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'GeneralInfo',
            Label : 'Breakdown Details',
            Target : '@UI.FieldGroup#GeneralInfo',
        },
    ],
);
