const cds = require('@sap/cds')

module.exports = cds.service.impl(async function () {

    // This runs when someone calls the findMatches action
    this.on('findMatches', 'BreakdownRequests', async (req) => {

        const requestID = req.params[0].ID  // ID comes from the URL path automatically

        // grab the DB tables we need
        const { BreakdownRequest, Inventory, Plants, MatchResult } = cds.entities('sparebridge')

        // STEP 1: Find the breakdown request
        const breakdown = await SELECT.one.from(BreakdownRequest).where({ ID: requestID })
        if (!breakdown) return req.error(404, 'Breakdown request not found')

        // Edge case: only run matching on NEW or PARTIAL requests
        if (breakdown.status === 'APPROVED') return req.error(400, 'Request is already fully approved — no more matching needed')

        // STEP 2: Get the GPS location of the plant that needs the part
        const needyPlant = await SELECT.one.from(Plants).where({ ID: breakdown.plant_ID })
        if (!needyPlant) return req.error(404, `Plant ${breakdown.plant_ID} not found`)

        // STEP 3: Find all inventory records for this material across all plants
        const allInventory = await SELECT.from(Inventory).where({ material: breakdown.material })

        // STEP 4: Keep only plants that have SPARE stock to give
        //   - not the same plant (no point sending to itself)
        //   - stock must be above safetyStock (surplus = stock - safetyStock)
        const surplusStocks = allInventory.filter(inv =>
            inv.plant_ID !== breakdown.plant_ID &&
            inv.stock > inv.safetyStock
        )

        // Edge case: no surplus found anywhere
        if (surplusStocks.length === 0) return req.error(404, 'No surplus stock found at any plant for this material')

        // STEP 5: For each surplus plant, calculate distance and transport cost
        const remainingQty = breakdown.quantity - (breakdown.fulfilledQty || 0)
        const candidates = []
        for (const inv of surplusStocks) {
            const sourcePlant = await SELECT.one.from(Plants).where({ ID: inv.plant_ID })
            if (!sourcePlant) continue  // skip this inventory row if plant data is missing

            const distKm = calcDistance(
                needyPlant.latitude, needyPlant.longitude,
                sourcePlant.latitude, sourcePlant.longitude
            )
            const transferableQty = inv.stock - inv.safetyStock
            const cost = Math.round(distKm * 10)  // simple rule: ₹10 per km

            const canFullyFulfil = transferableQty >= remainingQty
            candidates.push({ sourcePlant, transferableQty, distKm, cost, canFullyFulfil })
        }

        // STEP 6: Sort — full-fulfil plants first, then by distance within each group
        candidates.sort((a, b) => {
            if (a.canFullyFulfil && !b.canFullyFulfil) return -1  // a goes first
            if (!a.canFullyFulfil && b.canFullyFulfil) return 1   // b goes first
            return a.distKm - b.distKm                            // same group → closer first
        })

        // Edge case: delete previous match results if findMatches was called before
        // but skip matches that already have a TransferOrder (already approved)
        const { TransferOrder } = cds.entities('sparebridge')
        const existingMatches = await SELECT.from(MatchResult).columns('ID').where({ request_ID: requestID })
        let protectedCount = 0
        for (const m of existingMatches) {
            const hasOrder = await SELECT.one.from(TransferOrder).where({ match_ID: m.ID })
            if (!hasOrder) await DELETE.from(MatchResult).where({ ID: m.ID })
            else protectedCount++
        }

        // Update matchedAt timestamp so UI shows when matching was last run
        await UPDATE(BreakdownRequest).set({ matchedAt: new Date().toISOString() }).where({ ID: requestID })

        // STEP 7: Save each result to the MatchResult table and return them
        // rank starts after the protected (already approved) matches
        const saved = []
        for (let i = 0; i < candidates.length; i++) {
            const c = candidates[i]
            const match = {
                ID: cds.utils.uuid(),
                request_ID: requestID,
                sourcePlant_ID: c.sourcePlant.ID,
                transferableQty: c.transferableQty,
                distanceKm: c.distKm,
                estimatedCost: c.cost,
                canFullyFulfil: c.canFullyFulfil,
                rank: protectedCount + i + 1
            }
            await INSERT.into(MatchResult).entries(match)
            saved.push(match)
        }

        // Return updated BreakdownRequest so Fiori refreshes all fields including matchedAt
        return SELECT.one.from(BreakdownRequest).where({ ID: requestID })
    })

    this.on('approveMatch', 'MatchResults', async (req) => {

        const matchID = req.params[1].ID  // params[0]=BreakdownRequest key, params[1]=MatchResult key

        const { BreakdownRequest, Inventory, MatchResult, TransferOrder } = cds.entities('sparebridge')

        // STEP 1: Find the chosen match result
        const match = await SELECT.one.from(MatchResult).where({ ID: matchID })
        if (!match) return req.error(404, 'Match result not found')

        // STEP 2: Get the breakdown request linked to this match
        const breakdown = await SELECT.one.from(BreakdownRequest).where({ ID: match.request_ID })
        if (!breakdown) return req.error(404, 'Breakdown request not found')

        // Edge case: already fully fulfilled — no more approvals needed
        if (breakdown.status === 'APPROVED') return req.error(400, 'This breakdown request is already fully fulfilled')

        // Edge case: a TransferOrder already exists for this matchID (called twice)
        const existing = await SELECT.one.from(TransferOrder).where({ match_ID: matchID })
        if (existing) return req.error(400, 'A transfer order already exists for this match')

        // STEP 3: Re-verify sourcePlant still has enough stock (may have changed since matching)
        const inventory = await SELECT.one.from(Inventory).where({
            plant_ID: match.sourcePlant_ID,
            material: breakdown.material
        })
        if (!inventory) return req.error(404, 'Inventory record not found for source plant')

        // Calculate actual qty to send before checking stock
        const remainingQty = breakdown.quantity - (breakdown.fulfilledQty || 0)
        const qtyToSend = Math.min(match.transferableQty, remainingQty)

        const currentSurplus = inventory.stock - inventory.safetyStock
        if (currentSurplus < qtyToSend) return req.error(400, `Source plant stock too low — surplus is now only ${currentSurplus} unit(s)`)

        // STEP 4: Create the TransferOrder
        const transferOrder = {
            ID: cds.utils.uuid(),
            match_ID: matchID,
            request_ID: breakdown.ID,
            toPlant_ID: breakdown.plant_ID,
            quantity: qtyToSend,               // how many units are being transferred
            createdAt: new Date().toISOString(),
            status: 'PENDING',
            statusCriticality: 2
        }
        await INSERT.into(TransferOrder).entries(transferOrder)

        // STEP 5: Update fulfilledQty and decide the new status
        const newFulfilledQty = (breakdown.fulfilledQty || 0) + qtyToSend
        const newStatus = newFulfilledQty >= breakdown.quantity ? 'APPROVED' : 'PARTIAL'

        const newCriticality = newStatus === 'APPROVED' ? 3 : 2
        await UPDATE(BreakdownRequest)
            .set({ status: newStatus, fulfilledQty: newFulfilledQty, statusCriticality: newCriticality })
            .where({ ID: breakdown.ID })

        // Mark this match as APPROVED and disable its button
        await UPDATE(MatchResult)
            .set({ status: 'APPROVED', canApprove: false, statusCriticality: 3 })
            .where({ ID: matchID })

        // STEP 6: Deduct only what is actually being sent from sourcePlant inventory
        await UPDATE(Inventory)
            .set({ stock: inventory.stock - qtyToSend })
            .where({ plant_ID: match.sourcePlant_ID, material: breakdown.material })

        // Return updated BreakdownRequest so Fiori refreshes status and fulfilledQty
        return SELECT.one.from(BreakdownRequest).where({ ID: breakdown.ID })
    })

    // Mark STO as IN_TRANSIT — goods dispatched from source plant
    this.on('markInTransit', 'TransferOrders', async (req) => {
        const toID = req.params[1]?.ID || req.params[0].ID
        const { TransferOrder } = cds.entities('sparebridge')

        const to = await SELECT.one.from(TransferOrder).where({ ID: toID })
        if (!to) return req.error(404, 'Transfer order not found')
        if (to.status === 'DELIVERED') return req.error(400, 'Transfer order already delivered')

        await UPDATE(TransferOrder)
            .set({ status: 'IN_TRANSIT', statusCriticality: 2, canMarkShipped: false, canMarkDelivered: true })
            .where({ ID: toID })

        return SELECT.one.from(TransferOrder).where({ ID: toID })
    })

    // Mark STO as DELIVERED — goods received at breakdown plant
    this.on('markDelivered', 'TransferOrders', async (req) => {
        const toID = req.params[1]?.ID || req.params[0].ID
        const { TransferOrder } = cds.entities('sparebridge')

        const to = await SELECT.one.from(TransferOrder).where({ ID: toID })
        if (!to) return req.error(404, 'Transfer order not found')
        if (to.status === 'DELIVERED') return req.error(400, 'Transfer order already delivered')
        if (to.status !== 'IN_TRANSIT') return req.error(400, 'Must mark as shipped before marking delivered')

        await UPDATE(TransferOrder)
            .set({ status: 'DELIVERED', statusCriticality: 3, canMarkShipped: false, canMarkDelivered: false })
            .where({ ID: toID })

        return SELECT.one.from(TransferOrder).where({ ID: toID })
    })

})

// -------------------------------------------------------------------
// Helper: Haversine formula
// Calculates the real-world straight-line distance (km) between
// two GPS points given their latitude and longitude
// -------------------------------------------------------------------
function calcDistance(lat1, lon1, lat2, lon2) {
    const R = 6371  // Earth radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180
    const dLon = (lon2 - lon1) * Math.PI / 180
    const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) ** 2
    return Math.round(R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)))
}
