const cds = require('@sap/cds')

module.exports = cds.service.impl(async function () {

    // This runs when someone calls the findMatches action
    this.on('findMatches', async (req) => {

        const { requestID } = req.data  // the ID sent by the caller

        // grab the DB tables we need
        const { BreakdownRequest, Inventory, Plants, MatchResult } = cds.entities('sparebridge')

        // STEP 1: Find the breakdown request
        const breakdown = await SELECT.one.from(BreakdownRequest).where({ ID: requestID })
        if (!breakdown) return req.error(404, 'Breakdown request not found')

        // Edge case: only run matching on NEW requests
        if (breakdown.status !== 'NEW') return req.error(400, `Request is already ${breakdown.status} — cannot re-run matching`)

        // STEP 2: Get the GPS location of the plant that needs the part
        const needyPlant = await SELECT.one.from(Plants).where({ ID: breakdown.plant_ID })

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
        const candidates = []
        for (const inv of surplusStocks) {
            const sourcePlant = await SELECT.one.from(Plants).where({ ID: inv.plant_ID })

            const distKm = calcDistance(
                needyPlant.latitude, needyPlant.longitude,
                sourcePlant.latitude, sourcePlant.longitude
            )
            const transferableQty = inv.stock - inv.safetyStock
            const cost = Math.round(distKm * 10)  // simple rule: ₹10 per km

            const canFullyFulfil = transferableQty >= breakdown.quantity
            candidates.push({ sourcePlant, transferableQty, distKm, cost, canFullyFulfil })
        }

        // STEP 6: Sort — full-fulfil plants first, then by distance within each group
        candidates.sort((a, b) => {
            if (a.canFullyFulfil && !b.canFullyFulfil) return -1  // a goes first
            if (!a.canFullyFulfil && b.canFullyFulfil) return 1   // b goes first
            return a.distKm - b.distKm                            // same group → closer first
        })

        // Edge case: delete previous match results if findMatches was called before
        await DELETE.from(MatchResult).where({ request_ID: requestID })

        // STEP 7: Save each result to the MatchResult table and return them
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
                rank: i + 1
            }
            await INSERT.into(MatchResult).entries(match)
            saved.push(match)
        }

        return saved
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
