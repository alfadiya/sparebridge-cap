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
            Action : 'SpareBridgeService.findMatches',
        },
    ],

    // --- Color coding for breakdown status ---
    UI.DataPoint #StatusDP : {
        Value       : status,
        Criticality : statusCriticality
    },

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
            $Type  : 'UI.DataFieldForAnnotation',
            Label  : 'Status',
            Target : '@UI.DataPoint#StatusDP',
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
            {
                $Type : 'UI.DataField',
                Label : 'Matches Last Found',
                Value : matchedAt,
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
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'MatchResults',
            Label : 'Match Results',
            Target : 'matchResults/@UI.PresentationVariant',
        },
    ],
);

// --- Auto-refresh Match Results after findMatches runs ---
annotate service.BreakdownRequests actions {
    findMatches @(
        Common.SideEffects : {
            TargetEntities : [ $self, matchResults ]
        }
    )
};

// --- Auto-refresh Breakdown Details after approveMatch runs ---
annotate service.MatchResults actions {
    approveMatch @(
        Common.SideEffects : {
            TargetEntities : [ request ]
        }
    )
};

// --- Color coding for match result status ---
annotate service.MatchResults with @(
    UI.DataPoint #MatchStatusDP : {
        Value       : status,
        Criticality : statusCriticality
    }
);

// --- Disable Approve button when match is already approved ---
annotate service.MatchResults with actions {
    approveMatch @(Core.OperationAvailable : canApprove)
};

// --- Match Results table columns + Approve button ---
annotate service.MatchResults with @(
    UI.PresentationVariant : {
        SortOrder      : [{
            Property   : rank,
            Descending : false
        }],
        Visualizations : [ '@UI.LineItem' ]
    },
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Label : 'Rank',
            Value : rank,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Source Plant',
            Value : sourcePlant.name,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Distance (km)',
            Value : distanceKm,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Transferable Qty',
            Value : transferableQty,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Fulfils?',
            Value : canFullyFulfil,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Est. Cost (₹10/km)',
            Value : estimatedCost,
        },
        {
            $Type  : 'UI.DataFieldForAnnotation',
            Label  : 'Match Status',
            Target : '@UI.DataPoint#MatchStatusDP',
        },
        {
            $Type  : 'UI.DataFieldForAction',
            Label  : 'Approve',
            Action : 'SpareBridgeService.approveMatch',
            Inline : true,
        },
    ],
);
