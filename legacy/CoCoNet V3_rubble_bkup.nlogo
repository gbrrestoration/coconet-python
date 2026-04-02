;;  Scales resolved by CoCoNet:
;;    timestep = annual
;;    spatial scale = control site ~ 14 ha of reef ~ 8 ha coral habitat ~ 8 ha x 68 manta tows per ha ~ 544 manta tows
;;                    (Roelfsema et al. 2021 suggest total coral habitat is 6528 km^2. If model has 53443 sites, then each much encompass 12.2 ha of coral habitat).

;;  Resolved at site scale:
;;    rubble (R) .................. fractional cover of coral habitat
;;    coral (C) ................... fractional cover of coral habitat (5 functional groups)
;;    CoTS (S) .................... per hectare of coral habitat (6 age classes plus larvae)
;;    Benthic invertebrates (B) ... per hectare of coral habitat
;;    Triggerfish (T) ............. per hectare of coral habitat

;;  Resolved at reef scale:
;;    Emperors (E) ................ per hectare of coral habitat (5 age classes plus larval)
;;    Groupers (G) ................ per hectare of coral habitat (5 age classes plus larval)
;;    Fisheries data indicates mean catch (1989-2021) of emperors = 1.5 kg per ha per year
;;                                                       groupers = 3.0 kg per ha per year


extensions [ csv nw profiler ]
breed [ reefs reef ]
breed [ sites site ]
breed [ coasts coast ]
directed-link-breed [ coral-links coral-link ]
directed-link-breed [ cots-links cots-link ]
directed-link-breed [ emperor-links emperor-link ]
directed-link-breed [ grouper-links grouper-link ]
undirected-link-breed [ coast-links coast-link ]


globals
[
  ;; Parameter file contents

  ;; General parameters
  search-mode               ;; search for optimal deployment reefs (search-mode = 1) or not (search-mode = 0)

  small                     ;; small number (10e-6)
  year                      ;; date year (e.g. 2020)
  ensemble                  ;; ensemble run number
  per_km                    ;; approximate netlogo world units per km offshore
  ha_per_site               ;; number of hectares per control site (8)

  ;; Reef network and connectivity parameters
  number_of_reefs           ;; total number of reefs
  number_of_sites           ;; average number of sites per reef

  draw_year                 ;; randomly selected year to base connectivity on
  draw_month                ;; randomly selected month to base coral connectivity on
  draw_fortnight            ;; randomly selected month to base CoTS and fish connectivity on

  ;; Benthic invertebrate parameters
  B_recruit                  ;; recruitment per spawning benthic invertebrate
  B_max                      ;; maximum abundance per ha
  B_pred_S1                  ;; juvenile CoTS consumed per benthic invertebrates per year

  ;; Triggerfish parameters
  T_recruit                 ;; recruitment per spawning triggerfish
  T_max                     ;; maximum abundance per ha due to territorial behaviour
  T_pred_B                  ;; benthic invertebrates consumed per triggerfish per year (reduced by rubble cover)

  ;; Emperor fish parameters
  E_recruit                 ;; annual recruitment per emperor
  E_mort                    ;; mortality rate of emperors
  E_natal                   ;; average fraction of recruitment to natal reef [0 1]
  E_pred_S1                 ;; juvenile CoTS consumed per emperor per year
  E_pred_S                  ;; adult CoTS consumed per emperor per year

  ;; Grouper fish parameters
  G_recruit                 ;; annual recruitment per grouper
  G_mort                    ;; mortality rate of groupers
  G_pred_T                  ;; predation rate of groupers on triggerfish [0 1]

  ;; Fishery parameters
  reporting_ratio           ;; ratio of catch proportion reported prior to 2004 to catch proportion reported after 2004 [0 1]

  ;; Coral parameters
  rate_sa_i                 ;; initial growth rate of staghorn acropora coral (per year)
  rate_ta_i                 ;; initial growth rate of tabular acropora coral (per year)
  rate_mo_i                 ;; initial growth rate of monopora coral (per year)
  rate_fa_i                 ;; initial growth rate of favid coral (per year)
  rate_po_i                 ;; initial growth rate of poritidae coral (per year)
  rate_tt_i                 ;; initial growth rate of thermally tolerant coral

  thermal_sa_i              ;; initial thermal tolerance of staghorn acropora coral
  thermal_ta_i              ;; initial thermal tolerance of tabular acropora coral
  thermal_mo_i              ;; initial thermal tolerance of montipora corall
  thermal_fa_i              ;; initial thermal tolerance of favid coral
  thermal_po_i              ;; initial thermal tolerance of poritidae coral
  thermal_tt_i              ;; initial thermal tolerance of bleaching-resistant coral
  adaptability              ;; Adaptability of corals to thermal stress (e.g. adaptability = 1 implies doubling of thermal tolerance of corals as mortality approaches 100%)
  adapt_decay_time          ;; number of coral growth times (inverse of growth rate) for return of thermal tolerance to inital values (in the absence of bleaching stress)
  adapt_penalty             ;; reduction in growth rate per DHW of thermal tolerance natural adaptation (for all coral groups)
  adapt_plasticity          ;; maximum allowed change in thermal tolerance due to natural adaptation in DHW (for all coral groups)

  C_recruit                 ;; scaling of coral larval recruitment - increases coral cover

  ;; Rubble parameters
  rubble_decay_time         ;; exponential timescale (years) for recovery of substrate through natural rubble consolidation [1 infinity]

  ;; CoTS parameters
  S_spawning_threshold      ;; minimum COTS per 8 ha control site required for effective spawning
  S_spawning_failure        ;; long-term average probability of CoTS system-wide spawning failure
  S_phase                   ;; timing of CoTS outbreaks
  S_recruit                 ;; recruitment per spawning CoTS
  S_detectability           ;; detectability of CoTS by LTMP
  S_pred_C                  ;; consumption rate of CoTS on coral
  S_prefer                  ;; preference of CoTS for difference corals, higher values concentrate predation on faster growing corals
;  S_threshold               ;; CoTS per ha threshold for density effect on CoTS growth
  S_mort                    ;; natural mortality rate of juvenile CoTS (nominal age 4 year)
  S1_mort                   ;; natural mortality rate of juvenile CoTS (age 1 year)
  S2_mort                   ;; natural mortality rate of juvenile CoTS (age 1 year)
  S3_mort                   ;; natural mortality rate of juvenile CoTS (age 1 year)
  S4_mort                   ;; natural mortality rate of juvenile CoTS (age 1 year)
  S5_mort                   ;; natural mortality rate of juvenile CoTS (age 1 year)
  S6_mort                   ;; natural mortality rate of juvenile CoTS (age 1 year)

  ;; Output statistics
  monitored_reef_number     ;; the number (within NetLogo) of the monitoring reef nominated in the GUI
  monitor_S_adult           ;; abundance of COTS age 2-5+ at monitored reef
  monitor_C_total           ;; fraction cover of all coral types at monitored reef
  monitor_C_tt              ;; fraction cover of thermally tolerant coral at monitored reef
  monitor_total_outbreaks
  monitor_active_outbreaks

  ;; Environmental impact parameters
  cyclone_centre            ;; reef number where cyclone is centred
  cyclone_radius            ;; radius of cyclone: Puotinen, M., Maynard, J. A., Beeden, R., Radford, B. & Williams, G. J. A robust operational model for predicting where tropical cyclone waves damage coral reefs. Scientific reports 6, 1-12 (2016).
  cyclone_category          ;; category of cyclone [2 5]
  catchment_condition       ;; condition of catchments [0 1]
  flood_load                ;; relative impact of cyclone induced flooding taking into account catchment restoration [0 1]
  flood_scale               ;; offshore extent of flood influence in km - increases with flood load
  dhw_scale                 ;; average radius of bleaching impact in km per DHW
  pH_scale                  ;; offshore scale in km for increasing aragonite saturation state
  k_sa                      ;; magnitude of effect of pH on coral growth and recruitment
  k_ta                      ;; magnitude of effect of pH on coral growth and recruitment
  k_mo                      ;; magnitude of effect of pH on coral growth and recruitment
  k_fa                      ;; magnitude of effect of pH on coral growth and recruitment
  k_po                      ;; magnitude of effect of pH on coral growth and recruitment
  k_tt                      ;; magnitude of effect of pH on coral growth and recruitment

  ;; Intervention parameters not defined in GUI
  S_vessels                 ;; number of CoTS control vessels operating in each zone
  control_region            ;; FN, N, C or S

  ;; Intervention parameters also defined in GUI
  SSP
  ensemble-runs
  start-year
  save-year
  projection-year
  search-year
  end-year
  start-catchment-restore
  restore-timeframe
  start-CoTS-control
  eco-threshold
  CoTS-threshold
  coral-threshold
  CoTS-vessels-GBR
  CoTS-vessels-FN
  CoTS-vessels-N
  CoTS-vessels-C
  CoTS-vessels-S
  CoTS-vessels-sector
  intervene-lon-min
  intervene-lon-max
  intervene-lat-min
  intervene-lat-max
  start-modified-zoning
  rezoned-reefs
  start-modified-fishing
  catch-reduction
  start-lower-sizelimit
  start-upper-sizelimit
  start-CoTSlimit
  start-emperor-release
  release-reefs
  release-threshold
  release-number
  start-regional-shading
  regional-shading-reduction
  start-rubble-consolidation
  consolidation-reefs
  consolidation-threshold
  consolidation-hectares
  start-coral-seeding
  seed-reefs
  seed-threshold
  seed-hectares
  hybrid-fraction
  dominance
  start-coral-slick
  slick-reefs
  slick-threshold
  slick-hectares
  start-reef-shading
  shading-reefs
  reef-shading-reduction
  start-pH-protection
  pH-reefs
  pH-protection
]


sites-own
[
  B                        ;; benthic invertebrates at each site
  B_i                      ;; value of B at start-year
  T                        ;; triggerfish (and other invertivores e.g. cardinal fish) at each site - prey on invertebrates and are preyed on by groupers
  T_i                      ;; value of T at start-year

  S_0                      ;; abundance of COTS age 0 at each site (units of cots per ha)
  S_1                      ;; abundance of COTS age 1 at each site (units of cots per ha)
  S_2                      ;; abundance of COTS age 2 at each site (units of cots per ha)
  S_3                      ;; abundance of COTS age 3 at each site (units of cots per ha)
  S_4                      ;; abundance of COTS age 4 at each site (units of cots per ha)
  S_5                      ;; abundance of COTS age 5 at each site (units of cots per ha)
  S_6                      ;; abundance of COTS age 6+ at each site (units of cots per ha)
  S_manta                  ;; abundance of CoTS detected by manta tows at each site (units of cots per hectare)
  S_0_i                    ;; value of S_0 at start-year
  S_1_i
  S_2_i
  S_3_i
  S_4_i
  S_5_i
  S_6_i

  C_sa                     ;; cover of staghorn acropora coral on each site [0 1]
  C_ta                     ;; cover of tabular acropora coral on each site [0 1]
  C_mo                     ;; cover of montipora coral on each site [0 1]
  C_fa                     ;; cover of favid coral on each site [0 1]
  C_po                     ;; cover of poritidae coral on each site [0 1]
  C_tt                     ;; cover of thermally tolerant coral on each site [0 1]
  C_site                   ;; cover of coral on each site [0 1]
  C_sa_i                   ;; value of C_sa at start-year
  C_ta_i
  C_mo_i
  C_fa_i
  C_po_i
  C_tt_i
  C_site_i

  rate_sa                  ;; growth rate of staghorn acropora coral on each site (depends on thermal history)
  rate_ta                  ;; growth rate of tabular acropora coral on each site (depends on thermal history)
  rate_mo                  ;; growth rate of montipora coral on each site (depends on thermal history)
  rate_fa                  ;; growth rate of favid coral on each site (depends on thermal history)
  rate_po                  ;; growth rate of poritidae coral on each site (depends on thermal history)
  rate_tt                  ;; growth rate of thermally tolerant coral on each site (depends on thermal history)

  thermal_sa               ;; thermal tolerance of staghorn acropora coral
  thermal_ta               ;; thermal tolerance of tabular acropora coral
  thermal_mo               ;; thermal tolerance of montipora corall
  thermal_fa               ;; thermal tolerance of favid (brain) coral
  thermal_po               ;; thermal tolerance of poritidae (massive) coral
  thermal_tt               ;; thermal tolerance of thermally tolerant coral

  bleach_mort_sa           ;; bleaching induced mortality of staghorn acropora coral on each site
  bleach_mort_ta           ;; bleaching induced mortality of tabular acropora coral on each site
  bleach_mort_mo           ;; bleaching induced mortality of montipora coral on each site
  bleach_mort_fa           ;; bleaching induced mortality of favid coral on each site
  bleach_mort_po           ;; bleaching induced mortality of poritidae coral on each site
  bleach_mort_tt           ;; bleaching induced mortality of thermally tolerant coral on each site

  cyclone_mort_sa          ;; cyclone induced mortality of staghorn acropora coral on each site
  cyclone_mort_ta          ;; cyclone induced mortality of tabular acropora coral on each site
  cyclone_mort_mo          ;; cyclone induced mortality of montipora coral on each site
  cyclone_mort_fa          ;; cyclone induced mortality of favid coral on each site
  cyclone_mort_po          ;; cyclone induced mortality of poritidae coral on each site
  cyclone_mort_tt          ;; cyclone induced mortality of thermally tolerant coral on each site

  predate_mort_sa          ;; predation induced mortality of staghorn acropora coral on each site
  predate_mort_ta          ;; predation induced mortality of tabular acropora coral on each site
  predate_mort_mo          ;; predation induced mortality of montipora coral on each site
  predate_mort_fa          ;; predation induced mortality of favid coral on each site
  predate_mort_po          ;; predation induced mortality of poritidae coral on each site
  predate_mort_tt          ;; predation induced mortality of thermally tolerant coral on each site

  R_site                   ;; cover of coral rubble on each site [0 1]
  R_site_i                 ;; value of R_site at start-year
]


reefs-own
[
  reef_id
  region_name              ;; FN = far-north, N = north, C = central, S = south
  rezone_year              ;; year reef is rezoned from open to fishing (blue) to closed to fishing (green)
  future_rezone_year       ;; future year reef is rezoned from open to fishing (blue) to closed to fishing (green)
;  focus                    ;; reef or centroid of reefs being tested for best intervention location when search-mode is on: 0 = exclued with current run, 1 = included within current run
  benefit                  ;; cumulative benefit of intervention at a single reef when in search-mode
  x                        ;; longitude
  y                        ;; latitude
  shelf_position           ;; position of reef on shelf: I = inner-shelf, M = mid-shelf, O = outer-shelf
  sector_number            ;; AIMS sector [1 11]
  km_offshore              ;; distance of reef from the coast
  reef_sites               ;; number of sites on reef

  B_r                      ;; benthic invertebrates on each reef - prey on juvenile CoTS
  T_r                      ;; triggerfish on each reef - prey on invertebrates and are preyed on by groupers - no age classes because they mature in 1-year; high site fidelity due to territorial behaviour

  E_0                      ;; emperors represent direct CoTS predators (no lag): Lethrinus miniatus and L. nebulosus (redthroat and spangled emperors), Lethrinidae (emperors), Lutjanidae (tropical snappers).
  E_1
  E_2
  E_3
  E_4
  E_5
  E_0_i
  E_1_i
  E_2_i
  E_3_i
  E_4_i
  E_5_i
  E_catch_kg               ;; catch of emperors in kg at reef

  G_0                      ;; groupers represent predators of fish that prey on invertebrates that prey on CoTS (4-year lag): Plectropomus spp. and Variola spp. (coral trout), Serranidae (rockcods)
  G_1
  G_2
  G_3
  G_4
  G_5
  G_0_i
  G_1_i
  G_2_i
  G_3_i
  G_4_i
  G_5_i
  G_catch_kg               ;; catch of groupers in kg at reef

  S_1_r                    ;; abundance of CoTS age 1 on each reef
  S_2_r                    ;; abundance of CoTS age 2 on each reef (units of cots per hectare)
  S_3_r                    ;; abundance of CoTS age 3 on each reef (units of cots per hectare)
  S_4_r                    ;; abundance of CoTS age 4 on each reef (units of cots per hectare)
  S_5_r                    ;; abundance of CoTS age 5 on each reef (units of cots per hectare)
  S_6_r                    ;; abundance of CoTS age 6+ on each reef (units of cots per hectare)
  S_manta_r                ;; abundance of CoTS detected by manta tows on each reef (units of cots per hectare)

  C_sa_r                   ;; cover of staghorn acropora coral on each reef
  C_ta_r                   ;; cover of tabular acropora coral on each reef
  C_mo_r                   ;; cover of montipora coral on each reef
  C_fa_r                   ;; cover of favid coral on each reef
  C_po_r                   ;; cover of poritidae coral on each reef
  C_tt_r                   ;; cover of thermally tolerant coral on each reef
  C_reef                   ;; total reef coral cover = C_sa_r + C_ta_r + C_mo_r + C_fa_r + C_po_r + C_tt_r

  C_out_degree             ;; weighted out-degree measure in terms of realised recruitment taking into account coral cover on source reef

  bleach_mort_sa_r         ;; bleaching induced mortality of staghorn acropora coral on each site
  bleach_mort_ta_r         ;; bleaching induced mortality of tabular acropora coral on each site
  bleach_mort_mo_r         ;; bleaching induced mortality of montipora coral on each site
  bleach_mort_fa_r         ;; bleaching induced mortality of favid coral on each site
  bleach_mort_po_r         ;; bleaching induced mortality of poeritidae coral on each site
  bleach_mort_tt_r         ;; bleaching induced mortality of thermally tolerant coral on each site

  cyclone_mort_sa_r        ;; cyclone induced mortality of staghorn acropora coral on each reef
  cyclone_mort_ta_r        ;; cyclone induced mortality of tabular acropora coral on each reef
  cyclone_mort_mo_r        ;; cyclone induced mortality of montipora coral on each reef
  cyclone_mort_fa_r        ;; cyclone induced mortality of favid coral on each reef
  cyclone_mort_po_r        ;; cyclone induced mortality of poeritidae coral on each reef
  cyclone_mort_tt_r        ;; cyclone induced mortality of thermally tolerant coral on each reef

  predate_mort_sa_r        ;; predation induced mortality of staghorn acropora coral on each reef
  predate_mort_ta_r        ;; predation induced mortality of tabular acropora coral on each reef
  predate_mort_mo_r        ;; predation induced mortality of montipora coral on each reef
  predate_mort_fa_r        ;; predation induced mortality of favid coral on each reef
  predate_mort_po_r        ;; predation induced mortality of poeritidae coral on each reef
  predate_mort_tt_r        ;; predation induced mortality of thermally tolerant coral on each reef

  R_reef                   ;; total reef rubble cover

  dhw                      ;; degree heating weeks exposure
  reef_shading             ;; artificial protection from bleaching on each reef (e.g. fogging) expressed as the fractional reduction in degree heating weeks
  regional_shading         ;; artificial protection from bleaching at regional scale (e.g. cloud brightening) expressed as the fractional reduction in degree heating weeks
  pH_protect               ;; protection from ocean acidification effects through for example macroalgae farming [0 1]
  priority_category               ;; initial priority for CoTS control and other interventions (GBRMPA set = Y; other reefs = N)
  priority                 ;; priority for CoTS control and other interventions (GBRMPA set = 1-289; other reefs = 290-3753)
  dives_reef               ;; number of control dives on each reef (tracked for inclusion in output file)


  ;; dispersal kernals for corals (con=relative strength of connectivity; dir=direction of dispersal kernel; ang=angle of dispersal kernal; dis=distance of dispersal kernal)
  con1_oct15  dir1_oct15  ang1_oct15  dis1_oct15  con2_oct15  dir2_oct15  ang2_oct15  dis2_oct15
  con1_nov15  dir1_nov15  ang1_nov15  dis1_nov15  con2_nov15  dir2_nov15  ang2_nov15  dis2_nov15
  con1_dec15  dir1_dec15  ang1_dec15  dis1_dec15  con2_dec15  dir2_dec15  ang2_dec15  dis2_dec15

  con1_oct16  dir1_oct16  ang1_oct16  dis1_oct16  con2_oct16  dir2_oct16  ang2_oct16  dis2_oct16
  con1_nov16  dir1_nov16  ang1_nov16  dis1_nov16  con2_nov16  dir2_nov16  ang2_nov16  dis2_nov16
  con1_dec16  dir1_dec16  ang1_dec16  dis1_dec16  con2_dec16  dir2_dec16  ang2_dec16  dis2_dec16

  con1_oct17  dir1_oct17  ang1_oct17  dis1_oct17  con2_oct17  dir2_oct17  ang2_oct17  dis2_oct17
  con1_nov17  dir1_nov17  ang1_nov17  dis1_nov17  con2_nov17  dir2_nov17  ang2_nov17  dis2_nov17
  con1_dec17  dir1_dec17  ang1_dec17  dis1_dec17  con2_dec17  dir2_dec17  ang2_dec17  dis2_dec17

  con1_oct18  dir1_oct18  ang1_oct18  dis1_oct18  con2_oct18  dir2_oct18  ang2_oct18  dis2_oct18
  con1_nov18  dir1_nov18  ang1_nov18  dis1_nov18  con2_nov18  dir2_nov18  ang2_nov18  dis2_nov18
  con1_dec18  dir1_dec18  ang1_dec18  dis1_dec18  con2_dec18  dir2_dec18  ang2_dec18  dis2_dec18

  con1_oct19  dir1_oct19  ang1_oct19  dis1_oct19  con2_oct19  dir2_oct19  ang2_oct19  dis2_oct19
  con1_nov19  dir1_nov19  ang1_nov19  dis1_nov19  con2_nov19  dir2_nov19  ang2_nov19  dis2_nov19
  con1_dec19  dir1_dec19  ang1_dec19  dis1_dec19  con2_dec19  dir2_dec19  ang2_dec19  dis2_dec19

  con1_oct20  dir1_oct20  ang1_oct20  dis1_oct20  con2_oct20  dir2_oct20  ang2_oct20  dis2_oct20
  con1_nov20  dir1_nov20  ang1_nov20  dis1_nov20  con2_nov20  dir2_nov20  ang2_nov20  dis2_nov20
  con1_dec20  dir1_dec20  ang1_dec20  dis1_dec20  con2_dec20  dir2_dec20  ang2_dec20  dis2_dec20

  con1_oct21  dir1_oct21  ang1_oct21  dis1_oct21  con2_oct21  dir2_oct21  ang2_oct21  dis2_oct21
  con1_nov21  dir1_nov21  ang1_nov21  dis1_nov21  con2_nov21  dir2_nov21  ang2_nov21  dis2_nov21
  con1_dec21  dir1_dec21  ang1_dec21  dis1_dec21  con2_dec21  dir2_dec21  ang2_dec21  dis2_dec21


  ;; dispersal kernals for CoTS (a = first half of month, b = second half of month)
  con1_dec15a  dir1_dec15a  ang1_dec15a  dis1_dec15a  con2_dec15a  dir2_dec15a  ang2_dec15a  dis2_dec15a
  con1_dec15b  dir1_dec15b  ang1_dec15b  dis1_dec15b  con2_dec15b  dir2_dec15b  ang2_dec15b  dis2_dec15b

  con1_jan16a  dir1_jan16a  ang1_jan16a  dis1_jan16a  con2_jan16a  dir2_jan16a  ang2_jan16a  dis2_jan16a
  con1_jan16b  dir1_jan16b  ang1_jan16b  dis1_jan16b  con2_jan16b  dir2_jan16b  ang2_jan16b  dis2_jan16b
  con1_dec16a  dir1_dec16a  ang1_dec16a  dis1_dec16a  con2_dec16a  dir2_dec16a  ang2_dec16a  dis2_dec16a
  con1_dec16b  dir1_dec16b  ang1_dec16b  dis1_dec16b  con2_dec16b  dir2_dec16b  ang2_dec16b  dis2_dec16b

  con1_jan17a  dir1_jan17a  ang1_jan17a  dis1_jan17a  con2_jan17a  dir2_jan17a  ang2_jan17a  dis2_jan17a
  con1_jan17b  dir1_jan17b  ang1_jan17b  dis1_jan17b  con2_jan17b  dir2_jan17b  ang2_jan17b  dis2_jan17b
  con1_dec17a  dir1_dec17a  ang1_dec17a  dis1_dec17a  con2_dec17a  dir2_dec17a  ang2_dec17a  dis2_dec17a
  con1_dec17b  dir1_dec17b  ang1_dec17b  dis1_dec17b  con2_dec17b  dir2_dec17b  ang2_dec17b  dis2_dec17b

  con1_jan18a  dir1_jan18a  ang1_jan18a  dis1_jan18a  con2_jan18a  dir2_jan18a  ang2_jan18a  dis2_jan18a
  con1_jan18b  dir1_jan18b  ang1_jan18b  dis1_jan18b  con2_jan18b  dir2_jan18b  ang2_jan18b  dis2_jan18b
  con1_dec18a  dir1_dec18a  ang1_dec18a  dis1_dec18a  con2_dec18a  dir2_dec18a  ang2_dec18a  dis2_dec18a
  con1_dec18b  dir1_dec18b  ang1_dec18b  dis1_dec18b  con2_dec18b  dir2_dec18b  ang2_dec18b  dis2_dec18b

  con1_jan19a  dir1_jan19a  ang1_jan19a  dis1_jan19a  con2_jan19a  dir2_jan19a  ang2_jan19a  dis2_jan19a
  con1_jan19b  dir1_jan19b  ang1_jan19b  dis1_jan19b  con2_jan19b  dir2_jan19b  ang2_jan19b  dis2_jan19b
  con1_dec19a  dir1_dec19a  ang1_dec19a  dis1_dec19a  con2_dec19a  dir2_dec19a  ang2_dec19a  dis2_dec19a
  con1_dec19b  dir1_dec19b  ang1_dec19b  dis1_dec19b  con2_dec19b  dir2_dec19b  ang2_dec19b  dis2_dec19b

  con1_jan20a  dir1_jan20a  ang1_jan20a  dis1_jan20a  con2_jan20a  dir2_jan20a  ang2_jan20a  dis2_jan20a
  con1_jan20b  dir1_jan20b  ang1_jan20b  dis1_jan20b  con2_jan20b  dir2_jan20b  ang2_jan20b  dis2_jan20b
  con1_dec20a  dir1_dec20a  ang1_dec20a  dis1_dec20a  con2_dec20a  dir2_dec20a  ang2_dec20a  dis2_dec20a
  con1_dec20b  dir1_dec20b  ang1_dec20b  dis1_dec20b  con2_dec20b  dir2_dec20b  ang2_dec20b  dis2_dec20b

  con1_jan21a  dir1_jan21a  ang1_jan21a  dis1_jan21a  con2_jan21a  dir2_jan21a  ang2_jan21a  dis2_jan21a
  con1_jan21b  dir1_jan21b  ang1_jan21b  dis1_jan21b  con2_jan21b  dir2_jan21b  ang2_jan21b  dis2_jan21b
  con1_dec21a  dir1_dec21a  ang1_dec21a  dis1_dec21a  con2_dec21a  dir2_dec21a  ang2_dec21a  dis2_dec21a
  con1_dec21b  dir1_dec21b  ang1_dec21b  dis1_dec21b  con2_dec21b  dir2_dec21b  ang2_dec21b  dis2_dec21b

  con1_jan22a  dir1_jan22a  ang1_jan22a  dis1_jan22a  con2_jan22a  dir2_jan22a  ang2_jan22a  dis2_jan22a
  con1_jan22b  dir1_jan22b  ang1_jan22b  dis1_jan22b  con2_jan22b  dir2_jan22b  ang2_jan22b  dis2_jan22b


  ;; dispersal kernals for groupers (a = first half of month, b = second half of month)
  con1_dec15a_G  dir1_dec15a_G  ang1_dec15a_G  dis1_dec15a_G  con2_dec15a_G  dir2_dec15a_G  ang2_dec15a_G  dis2_dec15a_G
  con1_dec15b_G  dir1_dec15b_G  ang1_dec15b_G  dis1_dec15b_G  con2_dec15b_G  dir2_dec15b_G  ang2_dec15b_G  dis2_dec15b_G

  con1_jan16a_G  dir1_jan16a_G  ang1_jan16a_G  dis1_jan16a_G  con2_jan16a_G  dir2_jan16a_G  ang2_jan16a_G  dis2_jan16a_G
  con1_jan16b_G  dir1_jan16b_G  ang1_jan16b_G  dis1_jan16b_G  con2_jan16b_G  dir2_jan16b_G  ang2_jan16b_G  dis2_jan16b_G
  con1_dec16a_G  dir1_dec16a_G  ang1_dec16a_G  dis1_dec16a_G  con2_dec16a_G  dir2_dec16a_G  ang2_dec16a_G  dis2_dec16a_G
  con1_dec16b_G  dir1_dec16b_G  ang1_dec16b_G  dis1_dec16b_G  con2_dec16b_G  dir2_dec16b_G  ang2_dec16b_G  dis2_dec16b_G

  con1_jan17a_G  dir1_jan17a_G  ang1_jan17a_G  dis1_jan17a_G  con2_jan17a_G  dir2_jan17a_G  ang2_jan17a_G  dis2_jan17a_G
  con1_jan17b_G  dir1_jan17b_G  ang1_jan17b_G  dis1_jan17b_G  con2_jan17b_G  dir2_jan17b_G  ang2_jan17b_G  dis2_jan17b_G
  con1_dec17a_G  dir1_dec17a_G  ang1_dec17a_G  dis1_dec17a_G  con2_dec17a_G  dir2_dec17a_G  ang2_dec17a_G  dis2_dec17a_G
  con1_dec17b_G  dir1_dec17b_G  ang1_dec17b_G  dis1_dec17b_G  con2_dec17b_G  dir2_dec17b_G  ang2_dec17b_G  dis2_dec17b_G

  con1_jan18a_G  dir1_jan18a_G  ang1_jan18a_G  dis1_jan18a_G  con2_jan18a_G  dir2_jan18a_G  ang2_jan18a_G  dis2_jan18a_G
  con1_jan18b_G  dir1_jan18b_G  ang1_jan18b_G  dis1_jan18b_G  con2_jan18b_G  dir2_jan18b_G  ang2_jan18b_G  dis2_jan18b_G
  con1_dec18a_G  dir1_dec18a_G  ang1_dec18a_G  dis1_dec18a_G  con2_dec18a_G  dir2_dec18a_G  ang2_dec18a_G  dis2_dec18a_G
  con1_dec18b_G  dir1_dec18b_G  ang1_dec18b_G  dis1_dec18b_G  con2_dec18b_G  dir2_dec18b_G  ang2_dec18b_G  dis2_dec18b_G

  con1_jan19a_G  dir1_jan19a_G  ang1_jan19a_G  dis1_jan19a_G  con2_jan19a_G  dir2_jan19a_G  ang2_jan19a_G  dis2_jan19a_G
  con1_jan19b_G  dir1_jan19b_G  ang1_jan19b_G  dis1_jan19b_G  con2_jan19b_G  dir2_jan19b_G  ang2_jan19b_G  dis2_jan19b_G
  con1_dec19a_G  dir1_dec19a_G  ang1_dec19a_G  dis1_dec19a_G  con2_dec19a_G  dir2_dec19a_G  ang2_dec19a_G  dis2_dec19a_G
  con1_dec19b_G  dir1_dec19b_G  ang1_dec19b_G  dis1_dec19b_G  con2_dec19b_G  dir2_dec19b_G  ang2_dec19b_G  dis2_dec19b_G

  con1_jan20a_G  dir1_jan20a_G  ang1_jan20a_G  dis1_jan20a_G  con2_jan20a_G  dir2_jan20a_G  ang2_jan20a_G  dis2_jan20a_G
  con1_jan20b_G  dir1_jan20b_G  ang1_jan20b_G  dis1_jan20b_G  con2_jan20b_G  dir2_jan20b_G  ang2_jan20b_G  dis2_jan20b_G
  con1_dec20a_G  dir1_dec20a_G  ang1_dec20a_G  dis1_dec20a_G  con2_dec20a_G  dir2_dec20a_G  ang2_dec20a_G  dis2_dec20a_G
  con1_dec20b_G  dir1_dec20b_G  ang1_dec20b_G  dis1_dec20b_G  con2_dec20b_G  dir2_dec20b_G  ang2_dec20b_G  dis2_dec20b_G

  con1_jan21a_G  dir1_jan21a_G  ang1_jan21a_G  dis1_jan21a_G  con2_jan21a_G  dir2_jan21a_G  ang2_jan21a_G  dis2_jan21a_G
  con1_jan21b_G  dir1_jan21b_G  ang1_jan21b_G  dis1_jan21b_G  con2_jan21b_G  dir2_jan21b_G  ang2_jan21b_G  dis2_jan21b_G
  con1_dec21a_G  dir1_dec21a_G  ang1_dec21a_G  dis1_dec21a_G  con2_dec21a_G  dir2_dec21a_G  ang2_dec21a_G  dis2_dec21a_G
  con1_dec21b_G  dir1_dec21b_G  ang1_dec21b_G  dis1_dec21b_G  con2_dec21b_G  dir2_dec21b_G  ang2_dec21b_G  dis2_dec21b_G

  con1_jan22a_G  dir1_jan22a_G  ang1_jan22a_G  dis1_jan22a_G  con2_jan22a_G  dir2_jan22a_G  ang2_jan22a_G  dis2_jan22a_G
  con1_jan22b_G  dir1_jan22b_G  ang1_jan22b_G  dis1_jan22b_G  con2_jan22b_G  dir2_jan22b_G  ang2_jan22b_G  dis2_jan22b_G

]


to setup
    clear-all                                          ;; set parameters that apply to all domains, all reefs and all runs in ensemble
    random-seed ( 1 )

    set search-mode 0                                  ;; search for optimal deployment reefs (search-mode = 1) or not (search-mode = 0)

    ifelse ( file-exists? parameter-filename ) [ use-parameter-file  print "Parameters read from parameter file" ] [ use-interface  print "Parameters read from interface" ]  ;; check if a file with the name listed under "parameter-filename" in the Interface exists in the local directly. If not take parameters from the Interface.

    set small 0.000001

    set adaptability 1                                 ;; adaptability of corals to thermal stress (e.g. adaptability = 1 implies doubling of thermal tolerance of corals as mortality approaches 100%)
    set adapt_decay_time 10                            ;; timescale (years) for decay of enhanced thermal tolerance in the absence of heat stress due to genetic drift
    set adapt_penalty 0.05                             ;; 5% reduction in growth rate for every DHW increase in thermal tolerance gained through natural adaptation
    set adapt_plasticity 8                             ;; for sa thermal tolerance can go from 1.5 DHW to 6.5 DHW if there are 6 consecutive bleaching events (adaptability = 1), but no further.

    set rubble_decay_time 6                            ;; 5.5 years from ???? plus 0.5 years to account for time for bleached coral to form rubble [1 infinity]
    set per_km ( 2 * 500 ) / ( (25.5 - 10.5) * 111 )   ;; patches per km: North-South: 2 * 500 patches = (25.5 - 10.5) * 111 km (i.e. each patch is 0.015 degrees or 1.65 km)
    set ha_per_site 8
    set flood_scale 50                                 ;; offshore e-folding scale in km for decreasing flood-plume influence under maximum cyclone and poorest catchment condition ~ 50 km
    set flood_load 0.2

    set k_sa 0.0025                                    ;; calibrated to give ~40% reduction in coral growth rate by 2100 for SSP2-4.5 or RCP 4.5 (Dove et al. 2013); and between estimates of 6.9% (Albright et al. 2016) and 25% (Dove et al. 2013) for 2010-2020
    set k_ta 0.0020                                    ;; Acropora are very sensitive to OA (Albright et al. 2010, Fabricius et al. 2011)
    set k_mo 0.0005                                    ;; Montipora are insensitive across a wide pH range (Browne 2012)
    set k_po 0.0010                                    ;; Porites are relatively insensitive except in their recruitment phase (Fabricius et al. 2017)
    set k_fa 0.0020                                    ;; Favids are relatively sensitive
    set k_tt 0.0010                                    ;; Assumed to be relatively insensitive
    set pH_scale 100                                   ;; offshore e-folding scale in km for increasing coral growth ~ 100 km
    set dhw_scale 30 ;40                                   ;; average radius of bleaching impact in km per DHW

    set B_max 10000                                    ;; maximum CoTS predator benthic invertebrates per ha (10000 -> 1 per m^2)
    set B_recruit 0.5                                  ;; annual recruitment per benthic invertebrate
    set B_pred_S1 500                                  ;; juvenile CoTS consumed by benthic invertebrates per year, Wolfe ACRS conf: decorator crabs consumer 5 per day (90% benthic invertebrates & 10% fish (Keesing et al. 2018) -> B_max * B_pred_S1)

    set T_max 200                                      ;; maximum triggerfish per ha (Kavanagh and Olney 2006)
    set T_recruit 0.8                                  ;; annual recruitment per triggerfish
    set T_pred_B 120                                   ;; GUESS: benthic invertebrates consumed per triggerfish per annum

    set E_recruit 0.0028                               ;; annual recruitment per emperor
    set E_mort 0.026                                   ;; mortality rate of emperors
    set E_natal 0.1                                    ;; fraction of recruitment to natal reef [0 1] assumed high because they mature on seagrass before recruiting to reefs
    set E_pred_S1 500                                  ;; juvenile CoTS consumed per emperor per year (assuming 90% benthic invertebrates & 9% fish (Keesing et al. 2018))
    set E_pred_S 50                                    ;; adult CoTS consumed per emperor per year (inversely proportion to age of CoTS)

    set G_recruit 4                                    ;; annual recruitment per grouper
    set G_mort 0.01                                    ;; mortality rate of groupers
    set G_pred_T 70                                    ;; triggerfish consumed per grouper per annum

    set reporting_ratio 0.5                            ;; ratio of catch proportion reported prior to 2004 to catch proportion reported after 2004 rezoning [0 1]

    set rate_sa_i 0.50                                 ;; initial growth rates of coral groups - relative rates based on Hughes et al. 2018
    set rate_ta_i 0.40
    set rate_mo_i 0.30
    set rate_po_i 0.15
    set rate_fa_i 0.10
    set rate_tt_i 0.40

    set thermal_sa_i 1.5                               ;; 1.5 DHW
    set thermal_ta_i 2.0                               ;; 2.0 DHW
    set thermal_mo_i 3.0                               ;; 3.0 DHW
    set thermal_po_i 3.5                               ;; 3.5 DHW
    set thermal_fa_i 3.5                               ;; no significant difference according to Hughes et al. 2018
    set thermal_tt_i 7.5                               ;; Factor of 5 enhancement for thermally tolerant strain

    set C_recruit 0.05 ;0.04                                 ;; CALIBRATION PARAMETER: scaling of coral larval recruitment - increases coral cover

    set S_spawning_threshold 3                         ;; minimum COTS per hectare required for effective spawning from Rogers et al. (2017) (3 CoTS per Ha)
    set S_spawning_failure 0.7                         ;; CALIBRATION PARAMETER [0.4 0.8]: long-term average probability of system-wide CoTS spawning failure
    set S_phase 1                                      ;; CALIBRATION PARAMETER [0 15]: timing of CoTS outbreaks
    set S_recruit 300000 ;180000                                ;; CALIBRATION PARAMETER: scaling of CoTS larval recruitment - increases CoTS densities
    set S_pred_C 0.0003                                ;; consumption rate of CoTS on coral - one large CoTS can consume 0.001 ha of coral per year (AIMS website) => 0.00025
    set S_prefer 0.55                                  ;; CALIBRATION PARAMETER [0.1 0.4] - ENSURE THAT FASTEST GROWING CORALS MOST ABUNDANT, BUT ALL GROUPS PERSIST: preference of CoTS for difference corals, higher values concentrate predation on faster growing corals
    set S_mort 0.8 ;1.0 ;0.9                                     ;; CALIBRATION PARAMETER: minimum of CoTS mortality age distribution (~3-5 year old CoTS, younger and older have relatively much higher mortality)

    set S1_mort S_mort
    set S2_mort 0
    set S3_mort 0
    set S4_mort 0
    set S5_mort 0
    set S6_mort S_mort

    setup-GBR-coastline                                ;; setup coastline
    setup-GBR-reefs                                    ;; setup reefs
    set-up-output-files
    set ensemble 0

    reset-ticks
end


to use-interface
  set SSP SSP-i
  set ensemble-runs ensemble-runs-i
  set start-year start-year-i
  set save-year save-year-i
  set projection-year projection-year-i
  set search-year search-year-i
  set end-year end-year-i
  set start-catchment-restore start-catchment-restore-i
  set restore-timeframe restore-timeframe-i
  set start-CoTS-control start-CoTS-control-i
  set eco-threshold eco-threshold-i
  set CoTS-threshold CoTS-threshold-i
  set coral-threshold coral-threshold-i
  set CoTS-vessels-GBR CoTS-vessels-GBR-i
  set CoTS-vessels-FN CoTS-vessels-FN-i
  set CoTS-vessels-N CoTS-vessels-N-i
  set CoTS-vessels-C  CoTS-vessels-C-i
  set CoTS-vessels-S  CoTS-vessels-S-i
  set CoTS-vessels-sector  CoTS-vessels-sector-i
  set intervene-lon-min intervene-lon-min-i
  set intervene-lon-max intervene-lon-max-i
  set intervene-lat-min intervene-lat-min-i
  set intervene-lat-max intervene-lat-max-i
  set start-modified-zoning start-modified-zoning-i
  set rezoned-reefs rezoned-reefs-i
  set start-modified-fishing start-modified-fishing-i
  set catch-reduction catch-reduction-i
  set start-lower-sizelimit start-lower-sizelimit-i
  set start-upper-sizelimit start-upper-sizelimit-i
  set start-CoTSlimit start-CoTSlimit-i
  set start-emperor-release start-emperor-release-i
  set release-reefs release-reefs-i
  set release-threshold release-threshold-i
  set release-number release-number-i
  set start-regional-shading start-regional-shading-i
  set regional-shading-reduction regional-shading-reduction-i
  set start-rubble-consolidation start-rubble-consolidation-i
  set consolidation-reefs consolidation-reefs-i
  set consolidation-threshold consolidation-threshold-i
  set consolidation-hectares consolidation-hectares-i
  set start-coral-seeding start-coral-seeding-i
  set seed-reefs seed-reefs-i
  set seed-threshold seed-threshold-i
  set seed-hectares seed-hectares-i
  set hybrid-fraction hybrid-fraction-i
  set dominance dominance-i
  set start-coral-slick start-coral-slick-i
  set slick-reefs slick-reefs-i
  set slick-threshold slick-threshold-i
  set slick-hectares slick-hectares-i
  set start-reef-shading start-reef-shading-i
  set shading-reefs shading-reefs-i
  set reef-shading-reduction reef-shading-reduction-i
  set start-pH-protection start-pH-protection-i
  set pH-reefs pH-reefs-i
  set pH-protection pH-protection-i
end


to use-parameter-file
  file-close-all
  file-open parameter-filename
  let data csv:from-row file-read-line
  set data csv:from-row file-read-line  set SSP item 1 data
  set data csv:from-row file-read-line  set ensemble-runs item 1 data
  set data csv:from-row file-read-line  set start-year item 1 data
  set data csv:from-row file-read-line  set save-year item 1 data
  set data csv:from-row file-read-line  set projection-year item 1 data
  set data csv:from-row file-read-line  set search-year item 1 data
  set data csv:from-row file-read-line  set end-year item 1 data
  set data csv:from-row file-read-line  set start-catchment-restore item 1 data
  set data csv:from-row file-read-line  set restore-timeframe item 1 data
  set data csv:from-row file-read-line  set start-cots-control item 1 data
  set data csv:from-row file-read-line  set eco-threshold item 1 data
  set data csv:from-row file-read-line  set CoTS-threshold item 1 data
  set data csv:from-row file-read-line  set coral-threshold item 1 data
  set data csv:from-row file-read-line  set CoTS-vessels-GBR item 1 data
  set data csv:from-row file-read-line  set CoTS-vessels-FN item 1 data
  set data csv:from-row file-read-line  set CoTS-vessels-N item 1 data
  set data csv:from-row file-read-line  set CoTS-vessels-C item 1 data
  set data csv:from-row file-read-line  set CoTS-vessels-S item 1 data

  set data csv:from-row file-read-line  set CoTS-vessels-sector item 1 data

  set data csv:from-row file-read-line  set intervene-lon-min item 1 data
  set data csv:from-row file-read-line  set intervene-lon-max item 1 data
  set data csv:from-row file-read-line  set intervene-lat-min item 1 data
  set data csv:from-row file-read-line  set intervene-lat-max item 1 data
  set data csv:from-row file-read-line  set start-modified-zoning item 1 data
  set data csv:from-row file-read-line  set rezoned-reefs item 1 data
  set data csv:from-row file-read-line  set start-modified-fishing item 1 data
  set data csv:from-row file-read-line  set catch-reduction item 1 data
  set data csv:from-row file-read-line  set start-lower-sizelimit item 1 data
  set data csv:from-row file-read-line  set start-upper-sizelimit item 1 data
  set data csv:from-row file-read-line  set start-CoTSlimit item 1 data
  set data csv:from-row file-read-line  set start-emperor-release item 1 data
  set data csv:from-row file-read-line  set release-reefs item 1 data
  set data csv:from-row file-read-line  set release-threshold item 1 data
  set data csv:from-row file-read-line  set release-number item 1 data
  set data csv:from-row file-read-line  set start-regional-shading item 1 data
  set data csv:from-row file-read-line  set regional-shading-reduction item 1 data
  set data csv:from-row file-read-line  set start-rubble-consolidation item 1 data
  set data csv:from-row file-read-line  set consolidation-reefs item 1 data
  set data csv:from-row file-read-line  set consolidation-threshold item 1 data
  set data csv:from-row file-read-line  set consolidation-hectares item 1 data
  set data csv:from-row file-read-line  set start-coral-seeding item 1 data
  set data csv:from-row file-read-line  set seed-reefs item 1 data
  set data csv:from-row file-read-line  set seed-threshold item 1 data
  set data csv:from-row file-read-line  set seed-hectares item 1 data
  set data csv:from-row file-read-line  set hybrid-fraction item 1 data
  set data csv:from-row file-read-line  set dominance item 1 data
  set data csv:from-row file-read-line  set start-coral-slick item 1 data
  set data csv:from-row file-read-line  set slick-reefs item 1 data
  set data csv:from-row file-read-line  set slick-threshold item 1 data
  set data csv:from-row file-read-line  set slick-hectares item 1 data
  set data csv:from-row file-read-line  set start-reef-shading item 1 data
  set data csv:from-row file-read-line  set shading-reefs item 1 data
  set data csv:from-row file-read-line  set reef-shading-reduction item 1 data
  set data csv:from-row file-read-line  set start-pH-protection item 1 data
  set data csv:from-row file-read-line  set pH-reefs item 1 data
  set data csv:from-row file-read-line  set pH-protection item 1 data
end


to setup-GBR-reefs                                      ;; set up a network of reefs
  random-seed ( 1 )
  set-default-shape reefs "circle"

  file-close-all
  file-open "reefs2024.csv"
  let headings csv:from-row file-read-line
;  while [ not file-at-end? ]
  repeat 3806
  [
    let data csv:from-row file-read-line                ;; here the CSV extension grabs a single line and puts the read data in a list
    create-reefs 1
    [
      set reef_id item 1 data
      set y item 2 data
      set x item 3 data
      set region_name item 6 data                       ;; FN = far-north, N = north, C = central, S = south
      set shelf_position item 8 data
      set sector_number item 9 data                     ;; AIMS sector [1 11]
      set rezone_year item 10 data                      ;; year reef was rezoned from open to fishing (blue) to closed to fishing (green)
      set priority_category item 11 data                ;; N = nonpriority, P = priority, T = target or highest priority
      set reef_sites item 18 data

      ;; dispersal kernals for corals
      ;; con1=fraction of modelled larvae reaching other reefs within first cone
      ;; dir1=direction of first cone axis (clockwise from north)
      ;; ang1=internal angle of first cone angle
      ;; dis1=radial distance of first cone

      set con1_oct15 item 20 data      set dir1_oct15 item 21 data      set ang1_oct15 item 22 data      set dis1_oct15 item 23 data      set con2_oct15 item 24 data      set dir2_oct15 item 25 data      set ang2_oct15 item 26 data      set dis2_oct15 item 27 data
      set con1_nov15 item 29 data      set dir1_nov15 item 30 data      set ang1_nov15 item 31 data      set dis1_nov15 item 32 data      set con2_nov15 item 33 data      set dir2_nov15 item 34 data      set ang2_nov15 item 35 data      set dis2_nov15 item 36 data
      set con1_dec15 item 38 data      set dir1_dec15 item 39 data      set ang1_dec15 item 40 data      set dis1_dec15 item 41 data      set con2_dec15 item 42 data      set dir2_dec15 item 43 data      set ang2_dec15 item 44 data      set dis2_dec15 item 45 data

      set con1_oct16 item 47 data      set dir1_oct16 item 48 data      set ang1_oct16 item 49 data      set dis1_oct16 item 50 data      set con2_oct16 item 51 data      set dir2_oct16 item 52 data      set ang2_oct16 item 53 data      set dis2_oct16 item 54 data
      set con1_nov16 item 56 data      set dir1_nov16 item 57 data      set ang1_nov16 item 58 data      set dis1_nov16 item 59 data      set con2_nov16 item 60 data      set dir2_nov16 item 61 data      set ang2_nov16 item 62 data      set dis2_nov16 item 63 data
      set con1_dec16 item 65 data      set dir1_dec16 item 66 data      set ang1_dec16 item 67 data      set dis1_dec16 item 68 data      set con2_dec16 item 69 data      set dir2_dec16 item 70 data      set ang2_dec16 item 71 data      set dis2_dec16 item 72 data

      set con1_oct17 item 74 data      set dir1_oct17 item 75 data      set ang1_oct17 item 76 data      set dis1_oct17 item 77 data      set con2_oct17 item 78 data      set dir2_oct17 item 79 data      set ang2_oct17 item 80 data      set dis2_oct17 item 81 data
      set con1_nov17 item 83 data      set dir1_nov17 item 84 data      set ang1_nov17 item 85 data      set dis1_nov17 item 86 data      set con2_nov17 item 87 data      set dir2_nov17 item 88 data      set ang2_nov17 item 89 data      set dis2_nov17 item 90 data
      set con1_dec17 item 92 data      set dir1_dec17 item 93 data      set ang1_dec17 item 94 data      set dis1_dec17 item 95 data      set con2_dec17 item 96 data      set dir2_dec17 item 97 data      set ang2_dec17 item 98 data      set dis2_dec17 item 99 data

      set con1_oct18 item 101 data      set dir1_oct18 item 102 data      set ang1_oct18 item 103 data      set dis1_oct18 item 104 data      set con2_oct18 item 105 data      set dir2_oct18 item 106 data      set ang2_oct18 item 107 data      set dis2_oct18 item 108 data
      set con1_nov18 item 110 data      set dir1_nov18 item 111 data      set ang1_nov18 item 112 data      set dis1_nov18 item 113 data      set con2_nov18 item 114 data      set dir2_nov18 item 115 data      set ang2_nov18 item 116 data      set dis2_nov18 item 117 data
      set con1_dec18 item 119 data      set dir1_dec18 item 120 data      set ang1_dec18 item 121 data      set dis1_dec18 item 122 data      set con2_dec18 item 123 data      set dir2_dec18 item 124 data      set ang2_dec18 item 125 data      set dis2_dec18 item 126 data

      set con1_oct19 item 128 data      set dir1_oct19 item 129 data      set ang1_oct19 item 130 data      set dis1_oct19 item 131 data      set con2_oct19 item 132 data      set dir2_oct19 item 133 data      set ang2_oct19 item 134 data      set dis2_oct19 item 135 data
      set con1_nov19 item 137 data      set dir1_nov19 item 138 data      set ang1_nov19 item 139 data      set dis1_nov19 item 140 data      set con2_nov19 item 141 data      set dir2_nov19 item 142 data      set ang2_nov19 item 143 data      set dis2_nov19 item 144 data
      set con1_dec19 item 146 data      set dir1_dec19 item 147 data      set ang1_dec19 item 148 data      set dis1_dec19 item 149 data      set con2_dec19 item 150 data      set dir2_dec19 item 151 data      set ang2_dec19 item 152 data      set dis2_dec19 item 153 data

      set con1_oct20 item 155 data      set dir1_oct20 item 156 data      set ang1_oct20 item 157 data      set dis1_oct20 item 158 data      set con2_oct20 item 159 data      set dir2_oct20 item 160 data      set ang2_oct20 item 161 data      set dis2_oct20 item 162 data
      set con1_nov20 item 164 data      set dir1_nov20 item 165 data      set ang1_nov20 item 166 data      set dis1_nov20 item 167 data      set con2_nov20 item 168 data      set dir2_nov20 item 169 data      set ang2_nov20 item 170 data      set dis2_nov20 item 171 data
      set con1_dec20 item 173 data      set dir1_dec20 item 174 data      set ang1_dec20 item 175 data      set dis1_dec20 item 176 data      set con2_dec20 item 177 data      set dir2_dec20 item 178 data      set ang2_dec20 item 179 data      set dis2_dec20 item 180 data

      set con1_oct21 item 182 data      set dir1_oct21 item 183 data      set ang1_oct21 item 184 data      set dis1_oct21 item 185 data      set con2_oct21 item 186 data      set dir2_oct21 item 187 data      set ang2_oct21 item 188 data      set dis2_oct21 item 189 data
      set con1_nov21 item 191 data      set dir1_nov21 item 192 data      set ang1_nov21 item 193 data      set dis1_nov21 item 194 data      set con2_nov21 item 195 data      set dir2_nov21 item 196 data      set ang2_nov21 item 197 data      set dis2_nov21 item 198 data
      set con1_dec21 item 200 data      set dir1_dec21 item 201 data      set ang1_dec21 item 202 data      set dis1_dec21 item 203 data      set con2_dec21 item 204 data      set dir2_dec21 item 205 data      set ang2_dec21 item 206 data      set dis2_dec21 item 207 data

      ;; dispersal kernals for CoTS (a = first half of month, b = second half of month)
      ;; con1=fraction of modelled larvae reaching other reefs within first cone
      ;; dir1=direction of first cone axis (clockwise from north)
      ;; ang1=internal angle of first cone angle
      ;; dis1=radial distance of first cone

      set con1_dec15a item 209 data      set dir1_dec15a item 210 data      set ang1_dec15a item 211 data      set dis1_dec15a item 212 data      set con2_dec15a item 213 data      set dir2_dec15a item 214 data      set ang2_dec15a item 215 data      set dis2_dec15a item 216 data
      set con1_dec15b item 218 data      set dir1_dec15b item 219 data      set ang1_dec15b item 220 data      set dis1_dec15b item 221 data      set con2_dec15b item 222 data      set dir2_dec15b item 223 data      set ang2_dec15b item 224 data      set dis2_dec15b item 225 data
      set con1_jan16a item 227 data      set dir1_jan16a item 228 data      set ang1_jan16a item 229 data      set dis1_jan16a item 230 data      set con2_jan16a item 231 data      set dir2_jan16a item 232 data      set ang2_jan16a item 233 data      set dis2_jan16a item 234 data
      set con1_jan16b item 236 data      set dir1_jan16b item 237 data      set ang1_jan16b item 238 data      set dis1_jan16b item 239 data      set con2_jan16b item 240 data      set dir2_jan16b item 241 data      set ang2_jan16b item 242 data      set dis2_jan16b item 243 data

      set con1_dec16a item 245 data      set dir1_dec16a item 246 data      set ang1_dec16a item 247 data      set dis1_dec16a item 248 data      set con2_dec16a item 249 data      set dir2_dec16a item 250 data      set ang2_dec16a item 251 data      set dis2_dec16a item 252 data
      set con1_dec16b item 254 data      set dir1_dec16b item 255 data      set ang1_dec16b item 256 data      set dis1_dec16b item 257 data      set con2_dec16b item 258 data      set dir2_dec16b item 259 data      set ang2_dec16b item 260 data      set dis2_dec16b item 261 data
      set con1_jan17a item 263 data      set dir1_jan17a item 264 data      set ang1_jan17a item 265 data      set dis1_jan17a item 266 data      set con2_jan17a item 267 data      set dir2_jan17a item 268 data      set ang2_jan17a item 269 data      set dis2_jan17a item 270 data
      set con1_jan17b item 272 data      set dir1_jan17b item 273 data      set ang1_jan17b item 274 data      set dis1_jan17b item 275 data      set con2_jan17b item 276 data      set dir2_jan17b item 277 data      set ang2_jan17b item 278 data      set dis2_jan17b item 279 data

      set con1_dec17a item 281 data      set dir1_dec17a item 282 data      set ang1_dec17a item 283 data      set dis1_dec17a item 284 data      set con2_dec17a item 285 data      set dir2_dec17a item 286 data      set ang2_dec17a item 287 data      set dis2_dec17a item 288 data
      set con1_dec17b item 290 data      set dir1_dec17b item 291 data      set ang1_dec17b item 292 data      set dis1_dec17b item 293 data      set con2_dec17b item 294 data      set dir2_dec17b item 295 data      set ang2_dec17b item 296 data      set dis2_dec17b item 297 data
      set con1_jan18a item 299 data      set dir1_jan18a item 300 data      set ang1_jan18a item 301 data      set dis1_jan18a item 302 data      set con2_jan18a item 303 data      set dir2_jan18a item 304 data      set ang2_jan18a item 305 data      set dis2_jan18a item 306 data
      set con1_jan18b item 308 data      set dir1_jan18b item 309 data      set ang1_jan18b item 310 data      set dis1_jan18b item 311 data      set con2_jan18b item 312 data      set dir2_jan18b item 313 data      set ang2_jan18b item 314 data      set dis2_jan18b item 315 data

      set con1_dec18a item 317 data      set dir1_dec18a item 318 data      set ang1_dec18a item 319 data      set dis1_dec18a item 320 data      set con2_dec18a item 321 data      set dir2_dec18a item 322 data      set ang2_dec18a item 323 data      set dis2_dec18a item 324 data
      set con1_dec18b item 326 data      set dir1_dec18b item 327 data      set ang1_dec18b item 328 data      set dis1_dec18b item 329 data      set con2_dec18b item 330 data      set dir2_dec18b item 331 data      set ang2_dec18b item 332 data      set dis2_dec18b item 333 data
      set con1_jan19a item 335 data      set dir1_jan19a item 336 data      set ang1_jan19a item 337 data      set dis1_jan19a item 338 data      set con2_jan19a item 339 data      set dir2_jan19a item 340 data      set ang2_jan19a item 341 data      set dis2_jan19a item 342 data
      set con1_jan19b item 344 data      set dir1_jan19b item 345 data      set ang1_jan19b item 346 data      set dis1_jan19b item 347 data      set con2_jan19b item 348 data      set dir2_jan19b item 349 data      set ang2_jan19b item 350 data      set dis2_jan19b item 351 data

      set con1_dec19a item 353 data      set dir1_dec19a item 354 data      set ang1_dec19a item 355 data      set dis1_dec19a item 356 data      set con2_dec19a item 357 data      set dir2_dec19a item 358 data      set ang2_dec19a item 359 data      set dis2_dec19a item 360 data
      set con1_dec19b item 362 data      set dir1_dec19b item 363 data      set ang1_dec19b item 364 data      set dis1_dec19b item 365 data      set con2_dec19b item 366 data      set dir2_dec19b item 367 data      set ang2_dec19b item 368 data      set dis2_dec19b item 369 data
      set con1_jan20a item 371 data      set dir1_jan20a item 372 data      set ang1_jan20a item 373 data      set dis1_jan20a item 374 data      set con2_jan20a item 375 data      set dir2_jan20a item 376 data      set ang2_jan20a item 377 data      set dis2_jan20a item 378 data
      set con1_jan20b item 380 data      set dir1_jan20b item 381 data      set ang1_jan20b item 382 data      set dis1_jan20b item 383 data      set con2_jan20b item 384 data      set dir2_jan20b item 385 data      set ang2_jan20b item 386 data      set dis2_jan20b item 387 data

      set con1_dec20a item 389 data      set dir1_dec20a item 390 data      set ang1_dec20a item 391 data      set dis1_dec20a item 392 data      set con2_dec20a item 393 data      set dir2_dec20a item 394 data      set ang2_dec20a item 395 data      set dis2_dec20a item 396 data
      set con1_dec20b item 398 data      set dir1_dec20b item 399 data      set ang1_dec20b item 400 data      set dis1_dec20b item 401 data      set con2_dec20b item 402 data      set dir2_dec20b item 403 data      set ang2_dec20b item 404 data      set dis2_dec20b item 405 data
      set con1_jan21a item 407 data      set dir1_jan21a item 408 data      set ang1_jan21a item 409 data      set dis1_jan21a item 410 data      set con2_jan21a item 411 data      set dir2_jan21a item 412 data      set ang2_jan21a item 413 data      set dis2_jan21a item 414 data
      set con1_jan21b item 416 data      set dir1_jan21b item 417 data      set ang1_jan21b item 418 data      set dis1_jan21b item 419 data      set con2_jan21b item 420 data      set dir2_jan21b item 421 data      set ang2_jan21b item 422 data      set dis2_jan21b item 423 data

      set con1_dec21a item 425 data      set dir1_dec21a item 426 data      set ang1_dec21a item 427 data      set dis1_dec21a item 428 data      set con2_dec21a item 429 data      set dir2_dec21a item 430 data      set ang2_dec21a item 431 data      set dis2_dec21a item 432 data
      set con1_dec21b item 434 data      set dir1_dec21b item 435 data      set ang1_dec21b item 436 data      set dis1_dec21b item 437 data      set con2_dec21b item 438 data      set dir2_dec21b item 439 data      set ang2_dec21b item 440 data      set dis2_dec21b item 441 data
      set con1_jan22a item 443 data      set dir1_jan22a item 444 data      set ang1_jan22a item 445 data      set dis1_jan22a item 446 data      set con2_jan22a item 447 data      set dir2_jan22a item 448 data      set ang2_jan22a item 449 data      set dis2_jan22a item 450 data
      set con1_jan22b item 452 data      set dir1_jan22b item 453 data      set ang1_jan22b item 454 data      set dis1_jan22b item 455 data      set con2_jan22b item 456 data      set dir2_jan22b item 457 data      set ang2_jan22b item 458 data      set dis2_jan22b item 459 data

      ;; dispersal kernals for fish (a = first half of month, b = second half of month)
      ;; con1=fraction of modelled larvae reaching other reefs within first cone
      ;; dir1=direction of first cone axis (clockwise from north)
      ;; ang1=internal angle of first cone angle
      ;; dis1=radial distance of first cone

      set con1_dec15a_G item 461 data      set dir1_dec15a_G item 462 data      set ang1_dec15a_G item 463 data      set dis1_dec15a_G item 464 data      set con2_dec15a_G item 465 data      set dir2_dec15a_G item 466 data      set ang2_dec15a_G item 467 data      set dis2_dec15a_G item 468 data
      set con1_dec15b_G item 470 data      set dir1_dec15b_G item 471 data      set ang1_dec15b_G item 472 data      set dis1_dec15b_G item 473 data      set con2_dec15b_G item 474 data      set dir2_dec15b_G item 475 data      set ang2_dec15b_G item 476 data      set dis2_dec15b_G item 477 data
      set con1_jan16a_G item 479 data      set dir1_jan16a_G item 480 data      set ang1_jan16a_G item 481 data      set dis1_jan16a_G item 482 data      set con2_jan16a_G item 483 data      set dir2_jan16a_G item 484 data      set ang2_jan16a_G item 485 data      set dis2_jan16a_G item 486 data
      set con1_jan16b_G item 488 data      set dir1_jan16b_G item 489 data      set ang1_jan16b_G item 490 data      set dis1_jan16b_G item 491 data      set con2_jan16b_G item 492 data      set dir2_jan16b_G item 493 data      set ang2_jan16b_G item 494 data      set dis2_jan16b_G item 495 data

      set con1_dec16a_G item 497 data      set dir1_dec16a_G item 498 data      set ang1_dec16a_G item 499 data      set dis1_dec16a_G item 500 data      set con2_dec16a_G item 501 data      set dir2_dec16a_G item 502 data      set ang2_dec16a_G item 503 data      set dis2_dec16a_G item 504 data
      set con1_dec16b_G item 506 data      set dir1_dec16b_G item 507 data      set ang1_dec16b_G item 508 data      set dis1_dec16b_G item 509 data      set con2_dec16b_G item 510 data      set dir2_dec16b_G item 511 data      set ang2_dec16b_G item 512 data      set dis2_dec16b_G item 513 data
      set con1_jan17a_G item 515 data      set dir1_jan17a_G item 516 data      set ang1_jan17a_G item 517 data      set dis1_jan17a_G item 518 data      set con2_jan17a_G item 519 data      set dir2_jan17a_G item 520 data      set ang2_jan17a_G item 521 data      set dis2_jan17a_G item 522 data
      set con1_jan17b_G item 524 data      set dir1_jan17b_G item 525 data      set ang1_jan17b_G item 526 data      set dis1_jan17b_G item 527 data      set con2_jan17b_G item 528 data      set dir2_jan17b_G item 529 data      set ang2_jan17b_G item 530 data      set dis2_jan17b_G item 531 data

      set con1_dec17a_G item 533 data      set dir1_dec17a_G item 534 data      set ang1_dec17a_G item 535 data      set dis1_dec17a_G item 536 data      set con2_dec17a_G item 537 data      set dir2_dec17a_G item 538 data      set ang2_dec17a_G item 539 data      set dis2_dec17a_G item 540 data
      set con1_dec17b_G item 542 data      set dir1_dec17b_G item 543 data      set ang1_dec17b_G item 544 data      set dis1_dec17b_G item 545 data      set con2_dec17b_G item 546 data      set dir2_dec17b_G item 547 data      set ang2_dec17b_G item 548 data      set dis2_dec17b_G item 549 data
      set con1_jan18a_G item 551 data      set dir1_jan18a_G item 552 data      set ang1_jan18a_G item 553 data      set dis1_jan18a_G item 554 data      set con2_jan18a_G item 555 data      set dir2_jan18a_G item 556 data      set ang2_jan18a_G item 557 data      set dis2_jan18a_G item 558 data
      set con1_jan18b_G item 560 data      set dir1_jan18b_G item 561 data      set ang1_jan18b_G item 562 data      set dis1_jan18b_G item 563 data      set con2_jan18b_G item 564 data      set dir2_jan18b_G item 565 data      set ang2_jan18b_G item 566 data      set dis2_jan18b_G item 567 data

      set con1_dec18a_G item 569 data      set dir1_dec18a_G item 570 data      set ang1_dec18a_G item 571 data      set dis1_dec18a_G item 572 data      set con2_dec18a_G item 573 data      set dir2_dec18a_G item 574 data      set ang2_dec18a_G item 575 data      set dis2_dec18a_G item 576 data
      set con1_dec18b_G item 578 data      set dir1_dec18b_G item 579 data      set ang1_dec18b_G item 580 data      set dis1_dec18b_G item 581 data      set con2_dec18b_G item 582 data      set dir2_dec18b_G item 583 data      set ang2_dec18b_G item 584 data      set dis2_dec18b_G item 585 data
      set con1_jan19a_G item 587 data      set dir1_jan19a_G item 588 data      set ang1_jan19a_G item 589 data      set dis1_jan19a_G item 590 data      set con2_jan19a_G item 591 data      set dir2_jan19a_G item 592 data      set ang2_jan19a_G item 593 data      set dis2_jan19a_G item 594 data
      set con1_jan19b_G item 596 data      set dir1_jan19b_G item 597 data      set ang1_jan19b_G item 598 data      set dis1_jan19b_G item 599 data      set con2_jan19b_G item 600 data      set dir2_jan19b_G item 601 data      set ang2_jan19b_G item 602 data      set dis2_jan19b_G item 603 data

      set con1_dec19a_G item 605 data      set dir1_dec19a_G item 606 data      set ang1_dec19a_G item 607 data      set dis1_dec19a_G item 608 data      set con2_dec19a_G item 609 data      set dir2_dec19a_G item 610 data      set ang2_dec19a_G item 611 data      set dis2_dec19a_G item 612 data
      set con1_dec19b_G item 614 data      set dir1_dec19b_G item 615 data      set ang1_dec19b_G item 616 data      set dis1_dec19b_G item 617 data      set con2_dec19b_G item 618 data      set dir2_dec19b_G item 619 data      set ang2_dec19b_G item 620 data      set dis2_dec19b_G item 621 data
      set con1_jan20a_G item 623 data      set dir1_jan20a_G item 624 data      set ang1_jan20a_G item 625 data      set dis1_jan20a_G item 626 data      set con2_jan20a_G item 627 data      set dir2_jan20a_G item 628 data      set ang2_jan20a_G item 629 data      set dis2_jan20a_G item 630 data
      set con1_jan20b_G item 632 data      set dir1_jan20b_G item 633 data      set ang1_jan20b_G item 634 data      set dis1_jan20b_G item 635 data      set con2_jan20b_G item 636 data      set dir2_jan20b_G item 637 data      set ang2_jan20b_G item 638 data      set dis2_jan20b_G item 639 data

      set con1_dec20a_G item 641 data      set dir1_dec20a_G item 642 data      set ang1_dec20a_G item 643 data      set dis1_dec20a_G item 644 data      set con2_dec20a_G item 645 data      set dir2_dec20a_G item 646 data      set ang2_dec20a_G item 647 data      set dis2_dec20a_G item 648 data
      set con1_dec20b_G item 650 data      set dir1_dec20b_G item 651 data      set ang1_dec20b_G item 652 data      set dis1_dec20b_G item 653 data      set con2_dec20b_G item 654 data      set dir2_dec20b_G item 655 data      set ang2_dec20b_G item 656 data      set dis2_dec20b_G item 657 data
      set con1_jan21a_G item 659 data      set dir1_jan21a_G item 660 data      set ang1_jan21a_G item 661 data      set dis1_jan21a_G item 662 data      set con2_jan21a_G item 663 data      set dir2_jan21a_G item 664 data      set ang2_jan21a_G item 665 data      set dis2_jan21a_G item 666 data
      set con1_jan21b_G item 668 data      set dir1_jan21b_G item 669 data      set ang1_jan21b_G item 670 data      set dis1_jan21b_G item 671 data      set con2_jan21b_G item 672 data      set dir2_jan21b_G item 673 data      set ang2_jan21b_G item 674 data      set dis2_jan21b_G item 675 data

      set con1_dec21a_G item 677 data      set dir1_dec21a_G item 678 data      set ang1_dec21a_G item 679 data      set dis1_dec21a_G item 680 data      set con2_dec21a_G item 681 data      set dir2_dec21a_G item 682 data      set ang2_dec21a_G item 683 data      set dis2_dec21a_G item 684 data
      set con1_dec21b_G item 686 data      set dir1_dec21b_G item 687 data      set ang1_dec21b_G item 688 data      set dis1_dec21b_G item 689 data      set con2_dec21b_G item 690 data      set dir2_dec21b_G item 691 data      set ang2_dec21b_G item 692 data      set dis2_dec21b_G item 693 data
      set con1_jan22a_G item 695 data      set dir1_jan22a_G item 696 data      set ang1_jan22a_G item 697 data      set dis1_jan22a_G item 698 data      set con2_jan22a_G item 699 data      set dir2_jan22a_G item 700 data      set ang2_jan22a_G item 701 data      set dis2_jan22a_G item 702 data
      set con1_jan22b_G item 704 data      set dir1_jan22b_G item 705 data      set ang1_jan22b_G item 706 data      set dis1_jan22b_G item 707 data      set con2_jan22b_G item 708 data      set dir2_jan22b_G item 709 data      set ang2_jan22b_G item 710 data      set dis2_jan22b_G item 711 data

      set xcor 67 * ( x - 147.6 )
      set ycor 67 * ( y + 18 )
      set benefit 0
      set km_offshore ( distance min-one-of coasts [ distance myself ] ) / per_km      ;; distance of reef offshore in km
      set size max ( list 0.4 ( 4 * per_km * ( log ( 0.5 * reef_sites ) 10 ) ) )
      set color cyan + 2
      hatch-sites reef_sites [ set size 0 ]
    ]
  ]
  file-close
  set number_of_reefs count reefs
  set number_of_sites count sites
  let priority_reefs count reefs with [ priority_category = "P" ]
  let target_reefs count reefs with [ priority_category = "T" ]
;  let green_reefs count reefs with [ zoning = 1 ]
;  let blue_reefs count reefs with [ zoning = 0 ]
;  let priority_green_reefs count reefs with [ priority_category = "P" and zoning = 1 ]
;  let target_green_reefs count reefs with [ priority_category = "T" and zoning = 1 ]

  type "Number of reefs = " print number_of_reefs
  type "Number of sites " print number_of_sites
  type "Number of priority reefs = " print priority_reefs
  type "Number of target reefs = " print target_reefs
;  type "Number of Green Zone reefs = " print green_reefs
;  type "Number of Blue Zone reefs = " print blue_reefs
;  type "Number of Green priority reefs = " print priority_green_reefs
;  type "Number of Green target reefs = " print target_green_reefs
;  type "Number of reefs to be switched from Blue to Green = " print blue_to_green_reefs

;  type "Sites on priority reefs in FN = " print sum [ reef_sites ] of reefs with [ priority_category = "Y" and region_name = "FN" ]
;  type "Sites on priority reefs in N = " print sum [ reef_sites ] of reefs with [ priority_category = "Y" and region_name = "N" ]
;  type "Sites on priority reefs in C = " print sum [ reef_sites ] of reefs with [ priority_category = "Y" and region_name = "C" ]
;  type "Sites on priority reefs in S = " print sum [ reef_sites ] of reefs with [ priority_category = "Y" and region_name = "S" ]
end


to setup-GBR-coastline                                                                  ;; set up a coastline so that reef distance offshore is known
  random-seed ( 1 )
  file-open "coastline.csv"
  let headings csv:from-row file-read-line
  while [ not file-at-end? ]
  [
    let data csv:from-row file-read-line                  ; here the CSV extension grabs a single line and puts the read data in a list
    create-coasts 1
    [
      set xcor 67 * ( item 0 data - 147.6 )
      set ycor 67 * ( item 1 data + 18 )
      set shape "tree_coconut"
      set size 20
    ]
  ]
  file-close
  create-coasts 1                                         ;; emblem used on model interface
  [
    set xcor 0.6 * min-pxcor
    set ycor 0.6 * min-pycor
    set shape "tree_coconut"
    set size 200
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go                                                                   ;; run ensemble containing multiple runs
;;  profiler:start
  while [ ensemble <= ensemble-runs ]
  [
    initialise-run                                                      ;; reset all initial conditions for next run within ensemble
    type "ENSEMBLE = " print ensemble
    while [ year <= end-year ]
    [
      random-seed ( ( ensemble + 1 ) * year )                           ;; ensure different seeds even when ensemble = 0
      ask patches [ set pcolor black ]

      set draw_year ( 15 + random 7 )                                   ;; random draw from available spawning periods (7 years x 3 months = 21 options)
      if ( year = 2015 ) [ set draw_year 15 ]
      if ( year = 2016 ) [ set draw_year 16 ]
      if ( year = 2017 ) [ set draw_year 17 ]
      if ( year = 2018 ) [ set draw_year 18 ]
      if ( year = 2019 ) [ set draw_year 19 ]
      if ( year = 2020 ) [ set draw_year 20 ]
      if ( year = 2021 ) [ set draw_year 21 ]

      set draw_month ( 10 + random 3 )
      set draw_fortnight ( 1 + random 4 )
;      type "draw year = " print draw_year
;      type "draw month = " print draw_month

      cyclone                                                           ;; Jan-Mar

      random-seed ( ( ensemble + 1 ) * year )
      ifelse ( year < projection-year ) [ bleaching ]                   ;; Jan-Mar:
      [
        let prob 0
        if ( SSP = 1.9 ) [ set prob 0.39 - 0.00007 * ( year - 2070 ) ^ 2 ]             ;; Climate scenarios from McWhorter et al. (2022)
        if ( SSP = 2.6 ) [ set prob 0.47 - 0.00011 * ( year - 2070 ) ^ 2 ]
        if ( SSP = 4.5 ) [ set prob 0.70 - 0.00011 * ( year - 2090 ) ^ 2 ]
        if ( SSP = 7.0 ) [ set prob 0.98 - 0.00013 * ( year - 2100 ) ^ 2 ]
        if ( SSP = 8.5 ) [ set prob 0.98 - 0.00017 * ( year - 2090 ) ^ 2 ]
        if ( ( prob - 0.2 * ( cyclone_category - 0.5 ) / 4.5 ) ) > random-float ( 1.0 ) [ bleaching ]      ;; cyclones reduce risk of bleaching in the same year; average cyclone category based on probabilities is ~0.5; maximum reduction in probability is 0.2 (under category 5)
      ]
      ask reefs
      [
        set shape "circle"
        update-network-image
        grow-corals                                                     ;; Mar-Oct
        grow-cots                                                       ;; Mar-Oct
        grow-fish
        consume-corals                                                  ;; Mar-Oct
        consume-cots
        set dives_reef 0
      ]



;      print ( mean [ R_reef ] of reefs )



;;    Apply interventions
      if year >= start-CoTS-control
      [
        if ( CoTS-vessels-GBR > 0 )
        [
          set control_region "GBR"
          set S_vessels CoTS-vessels-GBR
          control-cots
        ]
        if ( CoTS-vessels-FN > 0 )
        [
          set control_region "FN"
          set S_vessels CoTS-vessels-FN
          control-cots
        ]
        if ( CoTS-vessels-N > 0 )
        [
          set control_region "N"
          set S_vessels CoTS-vessels-N
          control-cots
        ]
        if ( CoTS-vessels-C > 0 )
        [
          set control_region "C"
          set S_vessels CoTS-vessels-C
          control-cots
        ]
        if ( CoTS-vessels-S > 0 )
        [
          set control_region "S"
          set S_vessels CoTS-vessels-S
          control-cots
        ]
        if ( CoTS-vessels-sector > 0 )
        [
          set S_vessels CoTS-vessels-sector
          control-cots-by-sector
        ]
      ]

      if ( ( count reefs with [ year < rezone_year and year < future_rezone_year ] ) > 0 ) [ apply-fishing ]

      if year >= start-catchment-restore [ set catchment_condition catchment_condition + ( 1 - catchment_condition ) / restore-timeframe ]    ;; maximum = 1
      if year >= start-rubble-consolidation [ consolidate-rubble ]
      if year >= start-coral-seeding [ seed-tt-coral ]
      if year >= start-coral-slick [ seed-coral-slick ]
      if year >= start-emperor-release [ release-fish ]
      if year >= start-reef-shading [ shade-local-reef ]
      if year >= start-regional-shading [ shade-regional-coral ]
      if year >= start-pH-protection [ increase-pH ]



;     Apply perfect interventions from 2026

      if ( year >= 2026 and Perfect-intervention = "Starfish-control" )
      [
        print "Running perfect starfish control on an increasing number of reefs"
        ask reefs with [ priority <= ( 100 * ensemble ) ] [ ask sites-here [ set S_2 0  set S_3 0  set S_4 0  set S_5 0  set S_6 0 ] ]
      ]
      if ( year >= 2026 and Perfect-intervention = "Coral-replenishment" )
      [
        print "Running perfect coral replenishment on an increasing number of reefs"
        ask reefs with [ priority <= ( 100 * ensemble ) and C_reef < 0.2 ] [ ask sites-here with [ C_site < 0.2 ] [ set C_sa C_sa + 0.01 set C_ta C_ta + 0.01  set C_mo C_mo + 0.01 set C_po C_po + 0.01 set C_fa C_fa + 0.01 ] ]
      ]
      if ( year >= 2026 and Perfect-intervention = "Coral-enhancement" )
      [
        print "Running perfect coral enhancement on an increasing number of reefs"
        ask reefs with [ priority <= ( 100 * ensemble ) and C_reef < 0.2 ] [ ask sites-here with [ C_site < 0.2 ] [ set C_tt C_tt + 0.01 ] ]
      ]
      if ( year >= 2026 and Perfect-intervention = "Rubble-stabilisation" )
      [
        print "Running perfect rubble stabilisation on an increasing number of reefs"
        ask reefs with [ priority <= ( 100 * ensemble ) ] [ ask sites-here [ set R_site 0 ] ]
      ]
      if ( year >= 2026 and Perfect-intervention = "Coral-shading" )
      [
        print "Running perfect coral shading on an increasing number of reefs"
        ask reefs with [ priority <= ( 100 * ensemble ) ] [ set reef_shading 1.0 ]
      ]
      if ( year >= 2026 and Perfect-intervention = "Fish-protection" )
      [
        print "Running perfect fish protection on an increasing number of reefs"
        ask reefs with [ priority <= ( 100 * ensemble ) ] [ set future_rezone_year 2026 ]
      ]

      if ( year >= 2026 and Perfect-intervention = "ShadingPlusControl" )
      [
        print "Running perfect coral shading AND starfish control on an increasing number of reefs"
        ask reefs with [ priority <= ( 100 * ensemble ) ]
        [
          set reef_shading 1.0
          ask sites-here [ set S_2 0  set S_3 0  set S_4 0  set S_5 0  set S_6 0 ]
        ]
      ]



;      monitor-cots-coral
      ask reefs [ spawn-corals ]                                        ;; Oct, Nov or Dec

      if ( 0.5 * ( 1 + sin (2 * 3.1416 * ( 2010 + S_phase + random-float 4 - year ) / 16 ) ) > random-float ( 2 * S_spawning_failure ) ) [ ask reefs [ spawn-cots ] ]     ;; Dec-Feb: only in years where spawning succeeds; was 1998

      ask reefs [ spawn-fish ]                                          ;; Dec-Feb

      ;; Calculate population stats
      reef-populations
      if ( ensemble = 0 and year = start-year )
      [
        save-start-conditions
        set year end-year - 1
      ]
      if ( ensemble > 0 and year >= save-year and search-mode = 0 ) [ write-output ]
      set year year + 1
      tick
    ]
    if ( search-mode = 1 and year >= search-year )
    [
      file-open "priority_reef_benefit.csv"
      ask reefs with [ priority = 1 ] [ file-type reef_id file-type ", " file-type x file-type ", " file-type y file-type ", " file-print benefit ]   ;; print cumulative benefit of intervention over the run and over all sites
      file-close
    ]
    set ensemble ensemble + 1
  ]
;;  profiler:stop
;;  print profiler:report
;;  profiler:reset
end


to initialise-run                                                        ;; re-initialise each run within the broader ensemble
  random-seed ( ( ensemble + 1 ) * year )
  set catchment_condition 0
  let pH_x 1
  let Temp_y 1
  ask reefs                                                              ;; reset initial conditions for each run within ensemble
  [
    set future_rezone_year 9999                                                ;; reset so that a different set reefs are rezoned in each run of ensemble
    set Temp_y max ( list 0 ( 1.1 - ( ( y + 15 ) / 15 ) ^ 2 ) )           ;; growth increases with temperatue (https://www.nature.com/articles/s41598-017-03085-1) and mean over GBR is 1.0.
    set pH_x 1 - 0.20 * exp( -1 * km_offshore / pH_scale )               ;; inner GBR reefs growth rates are always ~20% less than outer GBR (Mongin et al. 2016)
    set pH_protect 0
    set reef_shading 0
    set regional_shading 0
    if search-mode = 1
    [
      if consolidation-reefs > 1 [ set consolidation-reefs 1 print "Warning: can only test one reef at a time when in search-mode"  ]
      if shading-reefs > 1 [ set shading-reefs 1 print "Warning: can only test one reef at a time when in search-mode"  ]
      if seed-reefs > 1 [ set seed-reefs 1 print "Warning: can only test one reef at a time when in search-mode"  ]
      if slick-reefs > 1 [ set slick-reefs 1 print "Warning: can only test one reef at a time when in search-mode"  ]
      if pH-reefs > 1 [ set pH-reefs 1 print "Warning: can only test one reef at a time when in search-mode"  ]
    ]
    ask sites-here
    [
      set rate_sa rate_sa_i * Temp_y * pH_x * ( 1.00 )                   ;; reset initial growth rates which decrease at higher latitude with falling temperatures (Anderson et al. 2017) and are higher offshore due to differences in aragonite saturation states
      set rate_ta rate_ta_i * Temp_y * pH_x * ( 1.00 * ( ( rate_sa_i / rate_ta_i ) ^ 0.073 ) )
      set rate_mo rate_mo_i * Temp_y * pH_x * ( 1.00 * ( ( rate_sa_i / rate_mo_i ) ^ 0.073 ) )
      set rate_po rate_po_i * Temp_y * pH_x * ( 1.00 * ( ( rate_sa_i / rate_po_i ) ^ 0.073 ) )
      set rate_fa rate_fa_i * Temp_y * pH_x * ( 1.00 * ( ( rate_sa_i / rate_fa_i ) ^ 0.073 ) )
      set rate_tt rate_tt_i * Temp_y * pH_x * ( 1.00 * ( ( rate_sa_i / rate_tt_i ) ^ 0.073 ) )  ;; 1.28 replaced by 1.00

      set thermal_sa thermal_sa_i
      set thermal_ta thermal_ta_i
      set thermal_mo thermal_mo_i
      set thermal_po thermal_po_i
      set thermal_fa thermal_fa_i
      set thermal_tt thermal_tt_i
    ]
  ]
  ifelse ( ensemble = 0 )
  [
    set year start-year - 50                                       ;; spin-up starts 50 years before start-year
    ask reefs                                                      ;; reset initial conditions for each run within ensemble
    [
      set E_5 0                                                    ;; maximum emperors per site is 0.0034 per m^2 or 34 per ha (based on 95th percentile of LTMP data)
      set E_4 1                                                    ;; initialised as 29 per ha on average
      set E_3 2
      set E_2 4
      set E_1 8
      set E_0 16

      set G_5 1                                                    ;; maximum groupers per site is 0.0070 per m^2 or 70 per ha (based on 95th percentile of LTMP data)
      set G_4 2                                                    ;; initialised as 58 per ha on average
      set G_3 4
      set G_2 8
      set G_1 16
      set G_0 32

      ask sites-here                                               ;; reset populations at every site on every reef
      [
        set B random ( 0.2 * B_max )
        set T random ( 0.2 * T_max )

        set S_6 0
        set S_5 0
        set S_4 1
        set S_3 5                                                  ;; assume 5 adult starfish per ha (or 33% incipient outbreak level)
        set S_2 20
        set S_1 100
        set S_0 500

        set C_sa 0.1                                              ;; reset coral cover at every site on every reef
        set C_ta 0.1
        set C_mo 0.1
        set C_po 0.1
        set C_fa 0.1
        set C_tt 0.0
        set C_site C_sa + C_ta + C_mo + C_po + C_fa + C_tt
        set R_site 0.2                                             ;; start with extensive rubble cover to limit coral growth during equilibration and allow CoTS settlement
      ]
    ]
  ]
  [
    set year start-year
    ask reefs                                                      ;; reset initial populations
    [
      set E_5 E_5_i
      set E_4 E_4_i
      set E_3 E_3_i
      set E_2 E_2_i
      set E_1 E_1_i
      set E_0 E_0_i

      set G_5 G_5_i
      set G_4 G_4_i
      set G_3 G_3_i
      set G_2 G_2_i
      set G_1 G_1_i
      set G_0 G_0_i

      ask sites-here
      [
        set B B_i
        set T T_i

        set S_6 S_6_i
        set S_5 S_5_i
        set S_4 S_4_i
        set S_3 S_3_i
        set S_2 S_2_i
        set S_1 S_1_i
        set S_0 S_0_i

        set C_sa C_sa_i
        set C_ta C_ta_i
        set C_mo C_mo_i
        set C_po C_po_i
        set C_fa C_fa_i
        set C_tt C_tt_i
        set C_site C_sa + C_ta + C_mo + C_po + C_fa + C_tt
        set R_site R_site_i
      ]
    ]
  ]
  reef-populations

  let p 1                                                   ;; reset reef priority always starting with target reefs and then priority reefs
  ask reefs with [ priority_category = "T" ]
  [
    set priority p
    if ( priority < rezoned-reefs and rezone_year = 9999 ) [ set future_rezone_year start-modified-zoning ]   ;; any zoning modification (blue to green) also starts with highest priority reefs
    set p p + 1
  ]
  ask reefs with [ priority_category = "P" ]
  [
    set priority p
    if ( priority < rezoned-reefs and rezone_year = 9999 ) [ set future_rezone_year start-modified-zoning ]
    set p p + 1
  ]
  ask reefs with [ priority_category = "N" ]
  [
    set priority p
    if ( priority < rezoned-reefs and rezone_year = 9999 ) [ set future_rezone_year start-modified-zoning ]
    set p p + 1
  ]

  if Unregulated-fishing? [ ask reefs [ set rezone_year 9999 set future_rezone_year 9999 ] ]   ;; no historical or future zoning or other restrictions on fishing

  let historical_green count reefs with [ rezone_year < 9999 ]
  let future_green count reefs with [ future_rezone_year < 9999 ]
  type "Number of historical green reefs = " print historical_green
  type "Number of future green reefs = " print future_green

end


to save-start-conditions
  ask reefs                                                  ;; reset initial conditions for each run within ensemble
  [
    set E_5_i E_5                                            ;; maximum emperors per site is 0.0034 per m^2 or 34 per ha (based on 95th percentile of LTMP data)
    set E_4_i E_4                                            ;; initialised as 15 per ha on average
    set E_3_i E_3
    set E_2_i E_2
    set E_1_i E_1
    set E_0_i E_0

    set G_5_i G_5                                            ;; maximum emperors per site is 0.0034 per m^2 or 34 per ha (based on 95th percentile of LTMP data)
    set G_4_i G_4                                            ;; initialised as 15 per ha on average
    set G_3_i G_3
    set G_2_i G_2
    set G_1_i G_1
    set G_0_i G_0

    ask sites-here                                           ;; reset populations at every site on every reef
    [
      set B_i B
      set T_i T

      set S_6_i S_6
      set S_5_i S_5
      set S_4_i S_4
      set S_3_i S_3                                          ;; assume average of 5 adult starfish per ha
      set S_2_i S_2
      set S_1_i S_1
      set S_0_i S_0

      set C_sa_i C_sa                                        ;; reset coral cover at every site on every reef
      set C_ta_i C_ta
      set C_mo_i C_mo
      set C_po_i C_po
      set C_fa_i C_fa
      set C_tt_i C_tt
      set C_site_i C_sa + C_ta + C_mo + C_po + C_fa + C_tt
      set R_site_i R_site                                    ;; start with extensive rubble cover to limit coral growth during equilibration allow CoTS settlement
    ]
  ]
end


to grow-fish                                                                ;; grow fishes on reef to next age-class including natural mortality and fishing mortality
  random-seed ( ( ensemble + 1 ) * year )
  let temp_depend 1 + 0.01 * ( y + 25 ) ^ 2                                 ;; min at 25 S and increases towards the equator
  let predation 0
  let K 0                                                                   ;; holding capacity
  let C_f 0
  let G_weighted ( G_1 + 2 * G_2 + 3 * G_3 + 4 * G_4 + 5 * G_5 ) / 15       ;; each groper age class consumes more than the previous

  ask sites-here
  [
    set C_f C_sa + C_mo + C_tt                                              ;; tabular coral excluded from cover for small fish as it is prefered ambush cover for groupers

    set predation T_pred_B * T * B / ( B + T_pred_B * T + small ) * exp ( -1 * ( C_site + R_site ) )    ;; predation of benthic invertebrates by trigger fish
    set B B * ( 1 + B_recruit ) - predation - B_recruit * B * B / B_max
    set B median ( list 100 B ( B_max * ( C_site + R_site ) ) )

    set predation G_pred_T * G_weighted * T / ( T + G_pred_T * G_weighted + small ) * exp ( -1 * C_site )
    set T T * ( 1 + T_recruit ) - predation - T_recruit * T * T / T_max
    set T median ( list 1 T (T_max * C_site ) )
  ]

  let mortality E_mort * temp_depend / ( 1 + C_reef )
  set E_5 round ( ( E_4 + E_5 ) * max ( list 0 ( 1 - 0.25 * mortality * ( E_4 + E_5 ) ) ) )      ;; quadratic closure term                                                                                        ;; natural mortality of adults decreases with age-class
  set E_4 round ( E_3 * max ( list 0 ( 1 - 0.33 * mortality * E_3 ) ) )
  set E_3 round ( E_2 * max ( list 0 ( 1 - 0.5 * mortality * E_2 ) ) )
  set E_2 round ( E_1 * max ( list 0 ( 1 - 1.0 * mortality * E_1 ) ) )
  set E_1 round ( E_0 * C_reef ^ 0.2)                                                            ;; juvenile dependence on coral cover

  set mortality G_mort * temp_depend / ( 1 + C_reef )
  set G_5 round ( ( G_4 + G_5 ) * max ( list 0 ( 1 - 0.25 * mortality * ( G_4 + G_5 ) ) ) )      ;; quadratic closure term                                                                                        ;; natural mortality of adults decreases with age-class
  set G_4 round ( G_3 * max ( list 0 ( 1 - 0.33 * mortality * G_3 ) ) )
  set G_3 round ( G_2 * max ( list 0 ( 1 - 0.5 * mortality * G_2 ) ) )
  set G_2 round ( G_1 * max ( list 0 ( 1 - 1.0 * mortality * G_1 ) ) )
  set G_1 round ( G_0 * C_reef ^ 0.2)                                                            ;; juvenile dependence on coral cover

end


to apply-fishing
  random-seed ( ( ensemble + 1 ) * year )
  let yy 0
  let prob_fish 0
  let effort 0
  let visits 0
  let max_visits 3000

  let kg_per_E_3 1.0                                  ;; average mass of E_3 fish based on fisheries data (caught from 3 years old)
  let kg_per_E_4 1.5                                  ;; average mass of E_4 fish
  let kg_per_E_5 2.5                                  ;; average mass of E_5 fish
  let kg_per_G_3 1.0                                  ;; average mass of G_3 fish (caught from 3 years old)
  let kg_per_G_4 1.5                                  ;; average mass of G_4 fish
  let kg_per_G_5 3.0                                  ;; average mass of G_5 fish

  let E_3_catch 0
  let E_4_catch 0
  let E_5_catch 0
  let G_3_catch 0
  let G_4_catch 0
  let G_5_catch 0
  let catch 0
  let E_annual_catch 0
  let G_annual_catch 0
  let E_cumulative_catch 0
  let G_cumulative_catch 0

  ask reefs
  [
    set E_catch_kg 0
    set G_catch_kg 0
  ]
  set E_annual_catch 0
  set G_annual_catch 0
  let reporting_rate 0.8 + random-float 0.2

  ifelse ( year < 2004 or Unregulated-fishing? )
  [
    set E_annual_catch max ( list 600000 ( 1500000 * ( 1 - exp ( -0.01 * exp ( 0.08 * ( year - 1940 ) ) ) ) ) ) / ( reporting_ratio * reporting_rate )     ;; fitted to QDAF data - rms error = 350000 kg
    set G_annual_catch max ( list 1160000 ( 2900000 * ( 1 - exp ( -0.01 * exp ( 0.08 * ( year - 1940 ) ) ) ) ) ) / ( reporting_ratio * reporting_rate )    ;; fitted to QDAF data - rms error = 850000 kg
  ]
  [
    set E_annual_catch 400000 / reporting_rate                                                                               ;; fitted to QDAF data
    set G_annual_catch 900000 / reporting_rate                                                                               ;; fitted to QDAF data
  ]
  if ( year >= start-modified-fishing )
  [
    set E_annual_catch E_annual_catch * ( 1 - catch-reduction )
    set G_annual_catch G_annual_catch * ( 1 - catch-reduction )
  ]

  set visits 0
  while [ E_cumulative_catch < E_annual_catch and visits < max_visits ]
  [
    ask one-of reefs with [ year < rezone_year and year < future_rezone_year ]    ;; select a reef that has not yet been rezoned to green
    [
      set yy 0.12 * ( 27 + y )
      set prob_fish 0.104 / yy * exp ( -2 * ( ln ( yy ) ) ^ 2 )               ;; latitude dependence follows a log normal distribution with approx 74% of blue zone reefs visited at peak (fitted to fisheries records)
      if ( random-float 1 < prob_fish )
      [
        set visits visits + 1
        set effort exp ( -1 * random-float 1 )                               ;; take of emperor falls off twice as rapidly as grouper
        set E_3_catch effort * E_3
        set E_4_catch effort * E_4
        set E_5_catch effort * E_5
        if ( year >= start-lower-sizelimit ) [ set E_3_catch 0 ]              ;; size limit applies to small fish
        if ( year >= start-upper-sizelimit ) [ set E_5_catch 0 ]              ;; size limit applies to large fish
        if ( year >= start-CoTSlimit and ( 0.55 * S_2_r + 0.70 * S_3_r + 0.85 * S_4_r + 0.95 * S_5_r + 0.99 * S_6_r ) > 68 ) [ set E_3_catch 0 set E_4_catch 0 set E_5_catch 0 ]   ;; exclude fishing from reefs with active outbreaks
        set E_3 max ( list 0 round ( E_3 - E_3_catch ) )
        set E_4 max ( list 0 round ( E_4 - E_4_catch ) )
        set E_5 max ( list 0 round ( E_5 - E_5_catch ) )
        set catch ( E_3_catch * kg_per_E_3 + E_4_catch * kg_per_E_4 + E_5_catch * kg_per_E_5 ) * reef_sites * ha_per_site
        set E_catch_kg E_catch_kg + catch                                    ;; tracked on each reef
        set E_cumulative_catch E_cumulative_catch + catch                    ;; tracked on GBR
      ]
    ]
  ]
  set visits 0
  while [ G_cumulative_catch < G_annual_catch and visits < max_visits ]
  [
    ask one-of reefs with [ year < rezone_year and year < future_rezone_year ]    ;; select a reef that has not yet been rezoned to green
    [
      set yy 0.17 * ( 25 + y )
      set prob_fish 0.18 / yy * exp ( -2 * ( ln ( yy ) ) ^ 2 )               ;; latitude dependence follows a log normal distribution with approx 74% of blue zone reefs visited at peak (fitted to fisheries records)
      if ( random-float 1 < prob_fish )
      [
        set visits visits + 1
        set effort exp ( -1 * random-float 1 )
        set G_3_catch effort * G_3
        set G_4_catch effort * G_4
        set G_5_catch effort * G_5
        if ( year >= start-lower-sizelimit ) [ set G_3_catch 0 ]              ;; size limit applies to small fish
        if ( year >= start-upper-sizelimit ) [ set G_5_catch 0 ]              ;; size limit applies to large fish
        if ( year >= start-CoTSlimit and ( 0.55 * S_2_r + 0.70 * S_3_r + 0.85 * S_4_r + 0.95 * S_5_r + 0.99 * S_6_r ) > 68 ) [ set G_3_catch 0 set G_4_catch 0 set G_5_catch 0 ]   ;; exclude fishing from reefs with active outbreaks
        set G_3 max ( list 0 round ( G_3 - G_3_catch ) )
        set G_4 max ( list 0 round ( G_4 - G_4_catch ) )
        set G_5 max ( list 0 round ( G_5 - G_5_catch ) )
        set catch ( G_3_catch * kg_per_G_3 + G_4_catch * kg_per_G_4 + G_5_catch * kg_per_G_5 ) * reef_sites * ha_per_site
        set G_catch_kg G_catch_kg + catch                                    ;; tracked on each reef
        set G_cumulative_catch G_cumulative_catch + catch                    ;; tracked on GBR
      ]
    ]
  ]
;;  type "visits = " print visits
end


to grow-corals                                                                                ;; grow corals on reef including the influences of flood plumes and ocean acidification
  random-seed ( ( ensemble + 1 ) * year )
  let flood_effect 0.1 + 0.9 * exp ( -1 * km_offshore / ( flood_scale * flood_load ) )        ;; coral growth decreases nearshore dependent on flood_load = [0.1 1.0]
  if flood_effect > 0.2 [ set pcolor brown ]
  let pH_effect_t 0
  if ( year >= projection-year ) [ set pH_effect_t ( 1 - pH_protect ) * sqrt( SSP ) ]         ;; pH_protect only applies to certain reefs


  let rubble_retention ( remainder who 11 ) / 20                                              ;; sets the maximum rubble cover that each site can hold [0 0.5], invariant over time.

;  type "rubble retention" print rubble_retention

  ask sites-here with [ ( C_site + R_site ) < 0.8 ]                                           ;; aggressive competition
  [
    set rate_sa rate_sa ^ ( 1 + pH_effect_t * k_sa )                                          ;; decline in growth rates due to decreasing aragonite saturation state
    set rate_ta rate_ta ^ ( 1 + pH_effect_t * k_ta )
    set rate_mo rate_mo ^ ( 1 + pH_effect_t * k_mo )
    set rate_po rate_po ^ ( 1 + pH_effect_t * k_po )
    set rate_fa rate_fa ^ ( 1 + pH_effect_t * k_fa )
    set rate_tt rate_tt ^ ( 1 + pH_effect_t * k_tt )

    set C_fa C_fa * ( 1 + rate_fa * ( 1 - flood_effect ) / ( 1 + sqrt ( C_site + R_site ) ) ) ;; Michaelis Menten equation for space limited growth
    set C_po C_po * ( 1 + rate_po * ( 1 - flood_effect ) / ( 1 + sqrt ( C_site + R_site ) ) )
    set C_mo C_mo * ( 1 + rate_mo * ( 1 - flood_effect ) / ( 1 + sqrt ( C_site + R_site ) ) )
    set C_ta C_ta * ( 1 + rate_ta * ( 1 - flood_effect ) / ( 1 + sqrt ( C_site + R_site ) ) )
    set C_tt C_tt * ( 1 + rate_tt * ( 1 - flood_effect ) / ( 1 + sqrt ( C_site + R_site ) ) )
    set C_sa C_sa * ( 1 + rate_sa * ( 1 - flood_effect ) / ( 1 + sqrt ( C_site + R_site ) ) )
    set C_site C_sa + C_ta + C_mo + C_fa + C_po + C_tt
  ]
  ask sites-here [ set R_site min ( list ( R_site * ( 1 - 1 / rubble_decay_time ) ) rubble_retention ) ]   ;; natural recovery of substrate and limitations on rubble capacity of reefs
  ask sites-here
  [
    if ( C_site + R_site ) > 0.7
    [
      set C_fa C_fa / ( C_site + R_site + 0.3 )
      set C_po C_po / ( C_site + R_site + 0.3 )
      set C_mo C_mo / ( C_site + R_site + 0.3 )
      set C_ta C_ta / ( C_site + R_site + 0.3 )
      set C_tt C_tt / ( C_site + R_site + 0.3 )
      set C_sa C_sa / ( C_site + R_site + 0.3 )
      set R_site R_site / ( C_site + R_site + 0.3 )
    ]
    set C_site C_sa + C_ta + C_mo + C_fa + C_po + C_tt
    if ( C_site + R_site ) > 1.0
    [
      set C_fa 0.1
      set C_po 0.1
      set C_mo 0.1
      set C_ta 0.1
      set C_tt 0.0
      set C_sa 0.1
      set C_site C_sa + C_ta + C_mo + C_fa + C_po + C_tt
      set R_site 0.1
    ]
  ]
end


to grow-cots                                                                                ;; grow CoTS on reef including natural mortality
  random-seed ( ( ensemble + 1 ) * year )
  let C_f 0
  let site_cap 0
  ask sites-here
  [
    set C_f median ( list 0 ( C_sa + C_ta + C_mo + C_tt ) 1 )
;    ifelse ( ( S_2 + S_3 + S_4 + S_5 + S_6 ) < S_density_threshold ) [ set weight 1 ] [ set weight ( ( S_2 + S_3 + S_4 + S_5 + S_6 ) / S_density_threshold ) ^ 2 ]   ;; density effects start at S_density_threshold per ha
    set site_cap sqrt ( C_f )   ; * exp ( - 1 * ( S_2 + S_3 + S_4 + S_5 + S_6 ) / S_threshold )                                                                                              ;; site_cap determines whether there is sufficient coral cover for juveniles to transition to adults
    set S_6 round ( ( S_5 + S_6 ) * exp ( - 1 * S6_mort / ( C_f + small ) ) )                       ;; senescence plateaus mortality from age 6
    set S_5 round ( S_4 * exp ( -1 * S5_mort / ( C_f + small ) ) )
    set S_4 round ( S_3 * exp ( -1 * S4_mort / ( C_f + small ) ) )
    set S_3 round ( S_2 * exp ( -1 * S3_mort / ( C_f + small ) ) )                                  ;; CoTS mortality = 0.519/age per year (Keesing et al. 2018, equation 4)
    set S_2 round ( S_1 * site_cap * exp ( -1 * S2_mort / ( C_f + small ) ) )                       ;; fraction of juvenile CoTS changing to adults increases with coral availability
    set S_1 round ( ( S_0 + S_1 * ( 1 - site_cap ) ) * exp ( -1 * S1_mort / ( R_site + small ) ) )  ;; mortality of juveniles in rubble + predation should be consistent with Keesing et al. (2018) ~ 0.0082 per day or 0.95 per annum -> S_mort = [0 0.95]
    set S_0 0
    set S_manta 0.50 * S_2 + 0.70 * S_3 + 0.85 * S_4 + 0.95 * S_5 + 0.99 * S_6                      ;; CoTS detected by manta tow at each site
  ]
end


to consume-corals                                                                            ;; CoTS consume corals
  random-seed ( ( ensemble + 1 ) * year )
  ask sites-here
  [
    let predation S_pred_C * ( 0.1 * S_1 + 1 * S_2 + 2 * S_3 + 3 * S_4 + 4 * S_5 + 5 * S_6 )        ;; each age class consumes more than the previous (Keesing and Lucas 1992)

    let consume_sa min ( list ( S_prefer * predation ) ( 0.9 * C_sa ) )
    set C_sa C_sa - consume_sa
    set R_site median ( list 0.0 1.0 ( R_site + 2 * consume_sa ) )
    set predation predation - consume_sa

    let consume_tt min ( list ( S_prefer * predation ) ( 0.9 * C_tt ) )
    set C_tt C_tt - consume_tt
    set R_site median ( list 0.0 1.0 ( R_site + 2 * consume_tt ) )
    set predation predation - consume_tt

    let consume_ta min ( list ( S_prefer * predation ) ( 0.9 * C_ta ) )
    set C_ta C_ta - consume_ta
    set R_site median ( list 0.0 1.0 ( R_site + 2 * consume_ta ) )
    set predation predation - consume_ta

    let consume_mo min ( list ( S_prefer * predation ) ( 0.9 * C_mo ) )
    set C_mo C_mo - consume_mo
    set R_site median ( list 0.0 1.0 ( R_site + 2 * consume_mo ) )
    set predation predation - consume_mo

    let consume_po min ( list ( S_prefer * predation ) ( 0.9 * C_po ) )
    set C_po C_po - consume_po
    set R_site median ( list 0.0 1.0 ( R_site + 2 * consume_po ) )
    set predation predation - consume_po

    let consume_fa min ( list ( S_prefer * predation ) ( 0.9 * C_fa ) )
    set C_fa C_fa - consume_fa
    set R_site median ( list 0.0 1.0 ( R_site + 2 * consume_fa ) )
    set predation predation - consume_fa
  ]
end


to consume-cots                                                                         ;; fish consume CoTS
  random-seed ( ( ensemble + 1 ) * year )
  let predation 0
  let E_site 0
  let E_weighted ( E_1 + 2 * E_2 + 3 * E_3 + 4 * E_4 + 5 * E_5 ) / 15                   ;; each emperor age class consumes more than the previous
  ask sites-here
  [
    set E_site random ( 2 * E_weighted )
    set predation B_pred_S1 * B * S_1 / ( S_1 + B_pred_S1 * B + small )                         ;; predation of juvenile CoTS by benthic invertebrates
    set S_1 round ( max ( list 10 ( S_1 - predation ) ) )                               ;; set minimum juvenile CoTS at say 10 per ha
    set predation E_pred_S1 * E_site * S_1 / ( S_1 + E_pred_S1 * E_site + small ) * exp ( -1 * R_site )   ;; predation of juvenile CoTS by emperors - limited by rubble cover
    set S_1 ceiling ( max ( list 10 ( S_1 - predation ) ) )                             ;; set minimum juvenile CoTS at say 10 per ha
    set predation E_pred_S * E_site * S_2 / ( S_2 + E_pred_S * E_site + small )                 ;; predation of adult CoTS by emperors
    set S_2 ceiling ( max ( list 1 ( S_2 - predation ) ) )
    set predation E_pred_S * E_site * S_3 / ( S_3 + E_pred_S * E_site + small )                 ;; predation of adult CoTS by emperors
    set S_3 ceiling ( max ( list 1 ( S_3 - predation ) ) )
    set predation E_pred_S * E_site * S_4 / ( S_4 + E_pred_S * E_site + small )                 ;; predation of adult CoTS by emperors
    set S_4 ceiling ( max ( list 1 ( S_4 - predation ) ) )
    set predation E_pred_S * E_site * S_5 / ( S_5 + E_pred_S * E_site + small )                 ;; predation of adult CoTS by emperors
    set S_5 ceiling ( max ( list 1 ( S_5 - predation ) ) )
    set predation E_pred_S * E_site * S_6 / ( S_6 + E_pred_S * E_site + small )                 ;; predation of adult CoTS by emperors
    set S_6 ceiling ( max ( list 1 ( S_6 - predation ) ) )
  ]
end


to spawn-fish                                                                           ;; spawn and recruit CoTS to natal reef and connected reefs
  random-seed ( ( ensemble + 1 ) * year )
  let n_sites reef_sites
  let predation 0
  let con1 0
  let con2 0
  let dir1 0
  let dir2 0
  let ang1 0
  let ang2 0
  let dis1 0
  let dis2 0
  let x_source xcor
  let y_source ycor

  if ( draw_year = 15 and draw_fortnight = 1 ) [ set con1 con1_dec15a_G     set con2 con2_dec15a_G     set dir1 dir1_dec15a_G     set dir2 dir2_dec15a_G     set ang1 ang1_dec15a_G     set ang2 ang2_dec15a_G     set dis1 dis1_dec15a_G     set dis2 dis2_dec15a_G ]
  if ( draw_year = 15 and draw_fortnight = 2 ) [ set con1 con1_dec15b_G     set con2 con2_dec15b_G     set dir1 dir1_dec15b_G     set dir2 dir2_dec15b_G     set ang1 ang1_dec15b_G     set ang2 ang2_dec15b_G     set dis1 dis1_dec15b_G     set dis2 dis2_dec15b_G ]
  if ( draw_year = 15 and draw_fortnight = 3 ) [ set con1 con1_jan16a_G     set con2 con2_jan16a_G     set dir1 dir1_jan16a_G     set dir2 dir2_jan16a_G     set ang1 ang1_jan16a_G     set ang2 ang2_jan16a_G     set dis1 dis1_jan16a_G     set dis2 dis2_jan16a_G ]
  if ( draw_year = 15 and draw_fortnight = 4 ) [ set con1 con1_jan16b_G     set con2 con2_jan16b_G     set dir1 dir1_jan16b_G     set dir2 dir2_jan16b_G     set ang1 ang1_jan16b_G     set ang2 ang2_jan16b_G     set dis1 dis1_jan16b_G     set dis2 dis2_jan16b_G ]

  if ( draw_year = 16 and draw_fortnight = 1 ) [ set con1 con1_dec16a_G     set con2 con2_dec16a_G     set dir1 dir1_dec16a_G     set dir2 dir2_dec16a_G     set ang1 ang1_dec16a_G     set ang2 ang2_dec16a_G     set dis1 dis1_dec16a_G     set dis2 dis2_dec16a_G ]
  if ( draw_year = 16 and draw_fortnight = 2 ) [ set con1 con1_dec16b_G     set con2 con2_dec16b_G     set dir1 dir1_dec16b_G     set dir2 dir2_dec16b_G     set ang1 ang1_dec16b_G     set ang2 ang2_dec16b_G     set dis1 dis1_dec16b_G     set dis2 dis2_dec16b_G ]
  if ( draw_year = 16 and draw_fortnight = 3 ) [ set con1 con1_jan17a_G     set con2 con2_jan17a_G     set dir1 dir1_jan17a_G     set dir2 dir2_jan17a_G     set ang1 ang1_jan17a_G     set ang2 ang2_jan17a_G     set dis1 dis1_jan17a_G     set dis2 dis2_jan17a_G ]
  if ( draw_year = 16 and draw_fortnight = 4 ) [ set con1 con1_jan17b_G     set con2 con2_jan17b_G     set dir1 dir1_jan17b_G     set dir2 dir2_jan17b_G     set ang1 ang1_jan17b_G     set ang2 ang2_jan17b_G     set dis1 dis1_jan17b_G     set dis2 dis2_jan17b_G ]

  if ( draw_year = 17 and draw_fortnight = 1 ) [ set con1 con1_dec17a_G     set con2 con2_dec17a_G     set dir1 dir1_dec17a_G     set dir2 dir2_dec17a_G     set ang1 ang1_dec17a_G     set ang2 ang2_dec17a_G     set dis1 dis1_dec17a_G     set dis2 dis2_dec17a_G ]
  if ( draw_year = 17 and draw_fortnight = 2 ) [ set con1 con1_dec17b_G     set con2 con2_dec17b_G     set dir1 dir1_dec17b_G     set dir2 dir2_dec17b_G     set ang1 ang1_dec17b_G     set ang2 ang2_dec17b_G     set dis1 dis1_dec17b_G     set dis2 dis2_dec17b_G ]
  if ( draw_year = 17 and draw_fortnight = 3 ) [ set con1 con1_jan18a_G     set con2 con2_jan18a_G     set dir1 dir1_jan18a_G     set dir2 dir2_jan18a_G     set ang1 ang1_jan18a_G     set ang2 ang2_jan18a_G     set dis1 dis1_jan18a_G     set dis2 dis2_jan18a_G ]
  if ( draw_year = 17 and draw_fortnight = 4 ) [ set con1 con1_jan18b_G     set con2 con2_jan18b_G     set dir1 dir1_jan18b_G     set dir2 dir2_jan18b_G     set ang1 ang1_jan18b_G     set ang2 ang2_jan18b_G     set dis1 dis1_jan18b_G     set dis2 dis2_jan18b_G ]

  if ( draw_year = 18 and draw_fortnight = 1 ) [ set con1 con1_dec18a_G     set con2 con2_dec18a_G     set dir1 dir1_dec18a_G     set dir2 dir2_dec18a_G     set ang1 ang1_dec18a_G     set ang2 ang2_dec18a_G     set dis1 dis1_dec18a_G     set dis2 dis2_dec18a_G ]
  if ( draw_year = 18 and draw_fortnight = 2 ) [ set con1 con1_dec18b_G     set con2 con2_dec18b_G     set dir1 dir1_dec18b_G     set dir2 dir2_dec18b_G     set ang1 ang1_dec18b_G     set ang2 ang2_dec18b_G     set dis1 dis1_dec18b_G     set dis2 dis2_dec18b_G ]
  if ( draw_year = 18 and draw_fortnight = 3 ) [ set con1 con1_jan19a_G     set con2 con2_jan19a_G     set dir1 dir1_jan19a_G     set dir2 dir2_jan19a_G     set ang1 ang1_jan19a_G     set ang2 ang2_jan19a_G     set dis1 dis1_jan19a_G     set dis2 dis2_jan19a_G ]
  if ( draw_year = 18 and draw_fortnight = 4 ) [ set con1 con1_jan19b_G     set con2 con2_jan19b_G     set dir1 dir1_jan19b_G     set dir2 dir2_jan19b_G     set ang1 ang1_jan19b_G     set ang2 ang2_jan19b_G     set dis1 dis1_jan19b_G     set dis2 dis2_jan19b_G ]

  if ( draw_year = 19 and draw_fortnight = 1 ) [ set con1 con1_dec19a_G     set con2 con2_dec19a_G     set dir1 dir1_dec19a_G     set dir2 dir2_dec19a_G     set ang1 ang1_dec19a_G     set ang2 ang2_dec19a_G     set dis1 dis1_dec19a_G     set dis2 dis2_dec19a_G ]
  if ( draw_year = 19 and draw_fortnight = 2 ) [ set con1 con1_dec19b_G     set con2 con2_dec19b_G     set dir1 dir1_dec19b_G     set dir2 dir2_dec19b_G     set ang1 ang1_dec19b_G     set ang2 ang2_dec19b_G     set dis1 dis1_dec19b_G     set dis2 dis2_dec19b_G ]
  if ( draw_year = 19 and draw_fortnight = 3 ) [ set con1 con1_jan20a_G     set con2 con2_jan20a_G     set dir1 dir1_jan20a_G     set dir2 dir2_jan20a_G     set ang1 ang1_jan20a_G     set ang2 ang2_jan20a_G     set dis1 dis1_jan20a_G     set dis2 dis2_jan20a_G ]
  if ( draw_year = 19 and draw_fortnight = 4 ) [ set con1 con1_jan20b_G     set con2 con2_jan20b_G     set dir1 dir1_jan20b_G     set dir2 dir2_jan20b_G     set ang1 ang1_jan20b_G     set ang2 ang2_jan20b_G     set dis1 dis1_jan20b_G     set dis2 dis2_jan20b_G ]

  if ( draw_year = 20 and draw_fortnight = 1 ) [ set con1 con1_dec20a_G     set con2 con2_dec20a_G     set dir1 dir1_dec20a_G     set dir2 dir2_dec20a_G     set ang1 ang1_dec20a_G     set ang2 ang2_dec20a_G     set dis1 dis1_dec20a_G     set dis2 dis2_dec20a_G ]
  if ( draw_year = 20 and draw_fortnight = 2 ) [ set con1 con1_dec20b_G     set con2 con2_dec20b_G     set dir1 dir1_dec20b_G     set dir2 dir2_dec20b_G     set ang1 ang1_dec20b_G     set ang2 ang2_dec20b_G     set dis1 dis1_dec20b_G     set dis2 dis2_dec20b_G ]
  if ( draw_year = 20 and draw_fortnight = 3 ) [ set con1 con1_jan21a_G     set con2 con2_jan21a_G     set dir1 dir1_jan21a_G     set dir2 dir2_jan21a_G     set ang1 ang1_jan21a_G     set ang2 ang2_jan21a_G     set dis1 dis1_jan21a_G     set dis2 dis2_jan21a_G ]
  if ( draw_year = 20 and draw_fortnight = 4 ) [ set con1 con1_jan21b_G     set con2 con2_jan21b_G     set dir1 dir1_jan21b_G     set dir2 dir2_jan21b_G     set ang1 ang1_jan21b_G     set ang2 ang2_jan21b_G     set dis1 dis1_jan21b_G     set dis2 dis2_jan21b_G ]

  if ( draw_year = 21 and draw_fortnight = 1 ) [ set con1 con1_dec21a_G     set con2 con2_dec21a_G     set dir1 dir1_dec21a_G     set dir2 dir2_dec21a_G     set ang1 ang1_dec21a_G     set ang2 ang2_dec21a_G     set dis1 dis1_dec21a_G     set dis2 dis2_dec21a_G ]
  if ( draw_year = 21 and draw_fortnight = 2 ) [ set con1 con1_dec21b_G     set con2 con2_dec21b_G     set dir1 dir1_dec21b_G     set dir2 dir2_dec21b_G     set ang1 ang1_dec21b_G     set ang2 ang2_dec21b_G     set dis1 dis1_dec21b_G     set dis2 dis2_dec21b_G ]
  if ( draw_year = 21 and draw_fortnight = 3 ) [ set con1 con1_jan22a_G     set con2 con2_jan22a_G     set dir1 dir1_jan22a_G     set dir2 dir2_jan22a_G     set ang1 ang1_jan22a_G     set ang2 ang2_jan22a_G     set dis1 dis1_jan22a_G     set dis2 dis2_jan22a_G ]
  if ( draw_year = 21 and draw_fortnight = 4 ) [ set con1 con1_jan22b_G     set con2 con2_jan22b_G     set dir1 dir1_jan22b_G     set dir2 dir2_jan22b_G     set ang1 ang1_jan22b_G     set ang2 ang2_jan22b_G     set dis1 dis1_jan22b_G     set dis2 dis2_jan22b_G ]

  let G_natal random-float ( exp ( -50 / sqrt ( reef_sites ) ) )                      ;; CHECK: larval retention set by Jim Greenwood analysis relating reefs (with number of sites) to max retention time and min settling time (11 days)
  let G_source ( G_2 + 2 * G_3 + 4 * G_4 + 8 * G_5 ) * ( 1 - 0.004 * ( y + 25 ) ^ 2 ) ;; Coral trout mature from 2-years with larval survival peaking at 20S (Pratchett et al. 2017)
  set G_0 random ( ( con1 + con2 ) * G_recruit * G_source * G_natal )                 ;; recruitment to natal reef

  if ( dis1 > 0 )                                                                     ;; first kernel
  [
    set heading dir1
    ask other reefs in-cone ( dis1 * per_km ) ang1
    [
      if ( ( distancexy x_source y_source ) < random-float ( dis1 * per_km ) )        ;; less likely to connect to reefs further away as sector arc widens linearly with distance
      [
        set G_0 G_0 + random ( con1 * G_recruit * G_source * ( 1 - G_natal ) * reef_sites )  ;; larger reef will capture more larvae
      ]
    ]
  ]

  if ( dis2 > 0 )                                                                     ;; second kernel
  [
    set heading dir2
    ask other reefs in-cone ( dis2 * per_km ) ang2
    [
      if ( ( distancexy x_source y_source ) < random-float ( dis2 * per_km ) )        ;; less likely to connect to reefs further away as sector arc widens linearly with distance
      [
        set G_0 G_0 + random ( con2 * G_recruit * G_source * ( 1 - G_natal ) * reef_sites )  ;; larger reef will capture more larvae
      ]
    ]
  ]

  let E_source ( E_4 + 2 * E_5 ) * ( 1 - 0.004 * ( y + 25 ) ^ 2 )                     ;; red throated emperors mature from 4-years (Sumpton & Brown 2004) with larval survival peaking at 20S similar to groupers
  set E_0 random ( E_recruit * E_source * E_natal * reef_sites )     ;; recruitment to natal reef, larger reef will retain more juveniles
  ask other reefs in-radius ( 100 * per_km )
  [
    set E_0 E_0 + random ( E_recruit * E_source * ( 1 - E_natal ) * reef_sites )      ;; larger reef will attract more juveniles
  ]
end


to spawn-corals                                                                       ;; spawn and recruit corals to natal reef and connected reefs
;;  nw:with-context reefs coral-links
  random-seed ( ( ensemble + 1 ) * year )
  let C_sa_source 0
  let C_ta_source 0
  let C_mo_source 0
  let C_po_source 0
  let C_fa_source 0
  let C_tt_source 0
  let thermal_sa_source 0
  let thermal_ta_source 0
  let thermal_mo_source 0
  let thermal_po_source 0
  let thermal_fa_source 0
  let thermal_tt_source 0
  let recruits 0
  let recruits_total 0
  set C_out_degree 0
  let limits 0
  let x_source xcor
  let y_source ycor
  let con1 0
  let con2 0
  let dir1 0
  let dir2 0
  let ang1 0
  let ang2 0
  let dis1 0
  let dis2 0

  ask one-of sites-here                                                                 ;; assume larvae are derived from a single site selected randomly from spawning reef (otherwise high thermal tolerance would be averaged away)
  [
    let hybrid hybrid-fraction * C_sa
    set C_sa_source ( C_sa - hybrid ) + hybrid * ( hybrid * hybrid + 2 * ( 1 -  dominance ) * hybrid * C_tt ) / (( hybrid + C_tt + small ) * ( hybrid + C_tt + small ))        ;; staghorn acropora have complete dominance when dominance = 0; bleaching-resistant have complete dominance when dominance = 1
    set C_ta_source C_ta
    set C_mo_source C_mo
    set C_po_source C_po
    set C_fa_source C_fa
    set C_tt_source C_tt * ( C_tt * ( ( 2 * dominance * hybrid ) + C_tt ) / ( ( hybrid + C_tt + small ) * ( hybrid + C_tt + small ) ) )
    set thermal_sa_source thermal_sa
    set thermal_ta_source thermal_ta
    set thermal_mo_source thermal_mo
    set thermal_po_source thermal_po
    set thermal_fa_source thermal_fa
    set thermal_tt_source thermal_tt
  ]
  if ( draw_year = 15 and draw_month = 10 ) [ set con1 con1_oct15    set con2 con2_oct15    set dir1 dir1_oct15    set dir2 dir2_oct15    set ang1 ang1_oct15    set ang2 ang2_oct15    set dis1 dis1_oct15    set dis2 dis2_oct15 ]
  if ( draw_year = 15 and draw_month = 11 ) [ set con1 con1_nov15    set con2 con2_nov15    set dir1 dir1_nov15    set dir2 dir2_nov15    set ang1 ang1_nov15    set ang2 ang2_nov15    set dis1 dis1_nov15    set dis2 dis2_nov15 ]
  if ( draw_year = 15 and draw_month = 12 ) [ set con1 con1_dec15    set con2 con2_dec15    set dir1 dir1_dec15    set dir2 dir2_dec15    set ang1 ang1_dec15    set ang2 ang2_dec15    set dis1 dis1_dec15    set dis2 dis2_dec15 ]
  if ( draw_year = 16 and draw_month = 10 ) [ set con1 con1_oct16    set con2 con2_oct16    set dir1 dir1_oct16    set dir2 dir2_oct16    set ang1 ang1_oct16    set ang2 ang2_oct16    set dis1 dis1_oct16    set dis2 dis2_oct16 ]
  if ( draw_year = 16 and draw_month = 11 ) [ set con1 con1_nov16    set con2 con2_nov16    set dir1 dir1_nov16    set dir2 dir2_nov16    set ang1 ang1_nov16    set ang2 ang2_nov16    set dis1 dis1_nov16    set dis2 dis2_nov16 ]
  if ( draw_year = 16 and draw_month = 12 ) [ set con1 con1_dec16    set con2 con2_dec16    set dir1 dir1_dec16    set dir2 dir2_dec16    set ang1 ang1_dec16    set ang2 ang2_dec16    set dis1 dis1_dec16    set dis2 dis2_dec16 ]
  if ( draw_year = 17 and draw_month = 10 ) [ set con1 con1_oct17    set con2 con2_oct17    set dir1 dir1_oct17    set dir2 dir2_oct17    set ang1 ang1_oct17    set ang2 ang2_oct17    set dis1 dis1_oct17    set dis2 dis2_oct17 ]
  if ( draw_year = 17 and draw_month = 11 ) [ set con1 con1_nov17    set con2 con2_nov17    set dir1 dir1_nov17    set dir2 dir2_nov17    set ang1 ang1_nov17    set ang2 ang2_nov17    set dis1 dis1_nov17    set dis2 dis2_nov17 ]
  if ( draw_year = 17 and draw_month = 12 ) [ set con1 con1_dec17    set con2 con2_dec17    set dir1 dir1_dec17    set dir2 dir2_dec17    set ang1 ang1_dec17    set ang2 ang2_dec17    set dis1 dis1_dec17    set dis2 dis2_dec17 ]
  if ( draw_year = 18 and draw_month = 10 ) [ set con1 con1_oct18    set con2 con2_oct18    set dir1 dir1_oct18    set dir2 dir2_oct18    set ang1 ang1_oct18    set ang2 ang2_oct18    set dis1 dis1_oct18    set dis2 dis2_oct18 ]
  if ( draw_year = 18 and draw_month = 11 ) [ set con1 con1_nov18    set con2 con2_nov18    set dir1 dir1_nov18    set dir2 dir2_nov18    set ang1 ang1_nov18    set ang2 ang2_nov18    set dis1 dis1_nov18    set dis2 dis2_nov18 ]
  if ( draw_year = 18 and draw_month = 12 ) [ set con1 con1_dec18    set con2 con2_dec18    set dir1 dir1_dec18    set dir2 dir2_dec18    set ang1 ang1_dec18    set ang2 ang2_dec18    set dis1 dis1_dec18    set dis2 dis2_dec18 ]
  if ( draw_year = 19 and draw_month = 10 ) [ set con1 con1_oct19    set con2 con2_oct19    set dir1 dir1_oct19    set dir2 dir2_oct19    set ang1 ang1_oct19    set ang2 ang2_oct19    set dis1 dis1_oct19    set dis2 dis2_oct19 ]
  if ( draw_year = 19 and draw_month = 11 ) [ set con1 con1_nov19    set con2 con2_nov19    set dir1 dir1_nov19    set dir2 dir2_nov19    set ang1 ang1_nov19    set ang2 ang2_nov19    set dis1 dis1_nov19    set dis2 dis2_nov19 ]
  if ( draw_year = 19 and draw_month = 12 ) [ set con1 con1_dec19    set con2 con2_dec19    set dir1 dir1_dec19    set dir2 dir2_dec19    set ang1 ang1_dec19    set ang2 ang2_dec19    set dis1 dis1_dec19    set dis2 dis2_dec19 ]
  if ( draw_year = 20 and draw_month = 10 ) [ set con1 con1_oct20    set con2 con2_oct20    set dir1 dir1_oct20    set dir2 dir2_oct20    set ang1 ang1_oct20    set ang2 ang2_oct20    set dis1 dis1_oct20    set dis2 dis2_oct20 ]
  if ( draw_year = 20 and draw_month = 11 ) [ set con1 con1_nov20    set con2 con2_nov20    set dir1 dir1_nov20    set dir2 dir2_nov20    set ang1 ang1_nov20    set ang2 ang2_nov20    set dis1 dis1_nov20    set dis2 dis2_nov20 ]
  if ( draw_year = 20 and draw_month = 12 ) [ set con1 con1_dec20    set con2 con2_dec20    set dir1 dir1_dec20    set dir2 dir2_dec20    set ang1 ang1_dec20    set ang2 ang2_dec20    set dis1 dis1_dec20    set dis2 dis2_dec20 ]
  if ( draw_year = 21 and draw_month = 10 ) [ set con1 con1_oct21    set con2 con2_oct21    set dir1 dir1_oct21    set dir2 dir2_oct21    set ang1 ang1_oct21    set ang2 ang2_oct21    set dis1 dis1_oct21    set dis2 dis2_oct21 ]
  if ( draw_year = 21 and draw_month = 11 ) [ set con1 con1_nov21    set con2 con2_nov21    set dir1 dir1_nov21    set dir2 dir2_nov21    set ang1 ang1_nov21    set ang2 ang2_nov21    set dis1 dis1_nov21    set dis2 dis2_nov21 ]
  if ( draw_year = 21 and draw_month = 12 ) [ set con1 con1_dec21    set con2 con2_dec21    set dir1 dir1_dec21    set dir2 dir2_dec21    set ang1 ang1_dec21    set ang2 ang2_dec21    set dis1 dis1_dec21    set dis2 dis2_dec21 ]

  if ( dis1 > 0 )
  [
    set heading dir1
    ask other reefs in-cone ( dis1 * per_km ) ang1
    [
      if ( ( distancexy x_source y_source ) < random-float ( dis1 * per_km ) )                                                   ;; less likely to connect to reefs further away as sector arc widens linearly with distance
      [
        ask sites-here
        [
          set limits C_recruit * con1 * median ( list 0 ( 1 - C_site - R_site ) 1 )                                              ;; recruitment reduces as sum of coral and rubble cover approaches 1

          set recruits random-float ( C_sa_source * limits ) * ( rate_sa / rate_sa_i )                                           ;; recruitment declines with OA following growth rate
          set thermal_sa max ( list 1 ( ( recruits * thermal_sa_source + C_sa * thermal_sa ) / ( recruits + C_sa + small ) ) )   ;; thermal tolerance is a weighted average of values for existing coral and new recruits with a minimum value of 1
          set C_sa C_sa + recruits
          set recruits_total recruits_total + recruits

          set recruits random-float ( C_tt_source * limits ) * ( rate_tt / rate_tt_i )                                           ;; recruitment declines with OA following growth rate
          set thermal_tt max ( list 1 ( ( recruits * thermal_tt_source + C_tt * thermal_tt ) / ( recruits + C_tt + small ) ) )   ;; thermal tolerance is a weighted average of values for existing coral and new recruits with a minimum value of 1
          set C_tt C_tt + recruits
          set recruits_total recruits_total + recruits

          set recruits random-float ( C_ta_source * limits ) * ( rate_ta / rate_ta_i )                                           ;; recruitment declines with OA following growth rate
          set thermal_ta max ( list 1 ( ( recruits * thermal_ta_source + C_ta * thermal_ta ) / ( recruits + C_ta + small ) ) )   ;; thermal tolerance is a weighted average of values for existing coral and new recruits with a minimum value of 1
          set C_ta C_ta + recruits
          set recruits_total recruits_total + recruits

          set recruits random-float ( C_mo_source * limits ) * ( rate_mo / rate_mo_i )                                           ;; recruitment declines with OA following growth rate
          set thermal_mo max ( list 1 ( ( recruits * thermal_mo_source + C_mo * thermal_mo ) / ( recruits + C_mo + small ) ) )   ;; thermal tolerance is a weighted average of values for existing coral and new recruits with a minimum value of 1
          set C_mo C_mo + recruits
          set recruits_total recruits_total + recruits

          set recruits random-float ( C_po_source * limits ) * ( rate_po / rate_po_i )                                           ;; recruitment declines with OA following growth rate
          set thermal_po max ( list 1 ( ( recruits * thermal_po_source + C_po * thermal_po ) / ( recruits + C_po + small ) ) )   ;; thermal tolerance is a weighted average of values for existing coral and new recruits with a minimum value of 1
          set C_po C_po + recruits
          set recruits_total recruits_total + recruits

          set recruits random-float ( C_fa_source * limits ) * ( rate_fa / rate_fa_i )                                           ;; recruitment declines with OA following growth rate
          set thermal_fa max ( list 1 ( ( recruits * thermal_fa_source + C_fa * thermal_fa ) / ( recruits + C_fa + small ) ) )   ;; thermal tolerance is a weighted average of values for existing coral and new recruits with a minimum value of 1
          set C_fa C_fa + recruits
          set recruits_total recruits_total + recruits
        ]
      ]
    ]
  ]

  if ( dis2 > 0 )
  [
    set heading dir2
    ask other reefs in-cone ( dis2 * per_km ) ang2
    [
      if ( ( distancexy x_source y_source ) < random-float ( dis2 * per_km ) )                                                   ;; less likely to connect to reefs further away as sector arc widens linearly with distance
      [
        ask sites-here
        [
          set limits C_recruit * con2 * median ( list 0 ( 1 - C_site - R_site ) 1 )                                            ;; recruitment reduces as sum of coral and rubble cover approaches 1

          set recruits random-float ( C_sa_source * limits ) * ( rate_sa / rate_sa_i )                                           ;; recruitment declines with OA following growth rate
          set thermal_sa max ( list 1 ( ( recruits * thermal_sa_source + C_sa * thermal_sa ) / ( recruits + C_sa + small ) ) )   ;; thermal tolerance is a weighted average of values for existing coral and new recruits with a minimum value of 1
          set C_sa C_sa + recruits
          set recruits_total recruits_total + recruits

          set recruits random-float ( C_tt_source * limits ) * ( rate_tt / rate_tt_i )                                           ;; recruitment declines with OA following growth rate
          set thermal_tt max ( list 1 ( ( recruits * thermal_tt_source + C_tt * thermal_tt ) / ( recruits + C_tt + small ) ) )   ;; thermal tolerance is a weighted average of values for existing coral and new recruits with a minimum value of 1
          set C_tt C_tt + recruits
          set recruits_total recruits_total + recruits

          set recruits random-float ( C_ta_source * limits ) * ( rate_ta / rate_ta_i )                                           ;; recruitment declines with OA following growth rate
          set thermal_ta max ( list 1 ( ( recruits * thermal_ta_source + C_ta * thermal_ta ) / ( recruits + C_ta + small ) ) )   ;; thermal tolerance is a weighted average of values for existing coral and new recruits with a minimum value of 1
          set C_ta C_ta + recruits
          set recruits_total recruits_total + recruits

          set recruits random-float ( C_mo_source * limits ) * ( rate_mo / rate_mo_i )                                           ;; recruitment declines with OA following growth rate
          set thermal_mo max ( list 1 ( ( recruits * thermal_mo_source + C_mo * thermal_mo ) / ( recruits + C_mo + small ) ) )   ;; thermal tolerance is a weighted average of values for existing coral and new recruits with a minimum value of 1
          set C_mo C_mo + recruits
          set recruits_total recruits_total + recruits

          set recruits random-float ( C_po_source * limits ) * ( rate_po / rate_po_i )                                           ;; recruitment declines with OA following growth rate
          set thermal_po max ( list 1 ( ( recruits * thermal_po_source + C_po * thermal_po ) / ( recruits + C_po + small ) ) )   ;; thermal tolerance is a weighted average of values for existing coral and new recruits with a minimum value of 1
          set C_po C_po + recruits
          set recruits_total recruits_total + recruits

          set recruits random-float ( C_fa_source * limits ) * ( rate_fa / rate_fa_i )                                           ;; recruitment declines with OA following growth rate
          set thermal_fa max ( list 1 ( ( recruits * thermal_fa_source + C_fa * thermal_fa ) / ( recruits + C_fa + small ) ) )   ;; thermal tolerance is a weighted average of values for existing coral and new recruits with a minimum value of 1
          set C_fa C_fa + recruits
          set recruits_total recruits_total + recruits
        ]
      ]
    ]
  ]

  ask sites-here
  [
    set C_site C_sa + C_ta + C_mo + C_fa + C_po + C_tt
    if ( C_site + R_site ) > 0.7
    [
      set C_fa C_fa / ( C_site + R_site + 0.3 )
      set C_po C_po / ( C_site + R_site + 0.3 )
      set C_mo C_mo / ( C_site + R_site + 0.3 )
      set C_ta C_ta / ( C_site + R_site + 0.3 )
      set C_tt C_tt / ( C_site + R_site + 0.3 )
      set C_sa C_sa / ( C_site + R_site + 0.3 )
    ]
    set C_site C_sa + C_ta + C_mo + C_fa + C_po + C_tt
    if ( C_site + R_site ) > 1.0
    [
      set C_fa 0.1
      set C_po 0.1
      set C_mo 0.1
      set C_ta 0.1
      set C_tt 0.0
      set C_sa 0.1
      set R_site 0.1
    ]
  ]
  set C_out_degree recruits_total
end


to spawn-cots                                                ;; spawn and recruit CoTS to natal reef and connected reefs
;;  nw:with-context reefs cots-links
  random-seed ( ( ensemble + 1 ) * year )
  let S_source 0
  let predation 0
  let Temp_y 1 - 0 * ( ( y + 15 ) / 18 ) ^ 2                      ;; CoTS mature faster at higher temperature and settle earlier
  let con1 0
  let con2 0
  let dir1 0
  let dir2 0
  let ang1 0
  let ang2 0
  let dis1 0
  let dis2 0
  let x_source xcor
  let y_source ycor

  if ( draw_year = 15 and draw_fortnight = 1 ) [ set con1 con1_dec15a      set con2 con2_dec15a      set dir1 dir1_dec15a      set dir2 dir2_dec15a      set ang1 ang1_dec15a      set ang2 ang2_dec15a      set dis1 dis1_dec15a      set dis2 dis2_dec15a ]
  if ( draw_year = 15 and draw_fortnight = 2 ) [ set con1 con1_dec15b      set con2 con2_dec15b      set dir1 dir1_dec15b      set dir2 dir2_dec15b      set ang1 ang1_dec15b      set ang2 ang2_dec15b      set dis1 dis1_dec15b      set dis2 dis2_dec15b ]
  if ( draw_year = 15 and draw_fortnight = 3 ) [ set con1 con1_jan16a      set con2 con2_jan16a      set dir1 dir1_jan16a      set dir2 dir2_jan16a      set ang1 ang1_jan16a      set ang2 ang2_jan16a      set dis1 dis1_jan16a      set dis2 dis2_jan16a ]
  if ( draw_year = 15 and draw_fortnight = 4 ) [ set con1 con1_jan16b      set con2 con2_jan16b      set dir1 dir1_jan16b      set dir2 dir2_jan16b      set ang1 ang1_jan16b      set ang2 ang2_jan16b      set dis1 dis1_jan16b      set dis2 dis2_jan16b ]

  if ( draw_year = 16 and draw_fortnight = 1 ) [ set con1 con1_dec16a      set con2 con2_dec16a      set dir1 dir1_dec16a      set dir2 dir2_dec16a      set ang1 ang1_dec16a      set ang2 ang2_dec16a      set dis1 dis1_dec16a      set dis2 dis2_dec16a ]
  if ( draw_year = 16 and draw_fortnight = 2 ) [ set con1 con1_dec16b      set con2 con2_dec16b      set dir1 dir1_dec16b      set dir2 dir2_dec16b      set ang1 ang1_dec16b      set ang2 ang2_dec16b      set dis1 dis1_dec16b      set dis2 dis2_dec16b ]
  if ( draw_year = 16 and draw_fortnight = 3 ) [ set con1 con1_jan17a      set con2 con2_jan17a      set dir1 dir1_jan17a      set dir2 dir2_jan17a      set ang1 ang1_jan17a      set ang2 ang2_jan17a      set dis1 dis1_jan17a      set dis2 dis2_jan17a ]
  if ( draw_year = 16 and draw_fortnight = 4 ) [ set con1 con1_jan17b      set con2 con2_jan17b      set dir1 dir1_jan17b      set dir2 dir2_jan17b      set ang1 ang1_jan17b      set ang2 ang2_jan17b      set dis1 dis1_jan17b      set dis2 dis2_jan17b ]

  if ( draw_year = 17 and draw_fortnight = 1 ) [ set con1 con1_dec17a      set con2 con2_dec17a      set dir1 dir1_dec17a      set dir2 dir2_dec17a      set ang1 ang1_dec17a      set ang2 ang2_dec17a      set dis1 dis1_dec17a      set dis2 dis2_dec17a ]
  if ( draw_year = 17 and draw_fortnight = 2 ) [ set con1 con1_dec17b      set con2 con2_dec17b      set dir1 dir1_dec17b      set dir2 dir2_dec17b      set ang1 ang1_dec17b      set ang2 ang2_dec17b      set dis1 dis1_dec17b      set dis2 dis2_dec17b ]
  if ( draw_year = 17 and draw_fortnight = 3 ) [ set con1 con1_jan18a      set con2 con2_jan18a      set dir1 dir1_jan18a      set dir2 dir2_jan18a      set ang1 ang1_jan18a      set ang2 ang2_jan18a      set dis1 dis1_jan18a      set dis2 dis2_jan18a ]
  if ( draw_year = 17 and draw_fortnight = 4 ) [ set con1 con1_jan18b      set con2 con2_jan18b      set dir1 dir1_jan18b      set dir2 dir2_jan18b      set ang1 ang1_jan18b      set ang2 ang2_jan18b      set dis1 dis1_jan18b      set dis2 dis2_jan18b ]

  if ( draw_year = 18 and draw_fortnight = 1 ) [ set con1 con1_dec18a      set con2 con2_dec18a      set dir1 dir1_dec18a      set dir2 dir2_dec18a      set ang1 ang1_dec18a      set ang2 ang2_dec18a      set dis1 dis1_dec18a      set dis2 dis2_dec18a ]
  if ( draw_year = 18 and draw_fortnight = 2 ) [ set con1 con1_dec18b      set con2 con2_dec18b      set dir1 dir1_dec18b      set dir2 dir2_dec18b      set ang1 ang1_dec18b      set ang2 ang2_dec18b      set dis1 dis1_dec18b      set dis2 dis2_dec18b ]
  if ( draw_year = 18 and draw_fortnight = 3 ) [ set con1 con1_jan19a      set con2 con2_jan19a      set dir1 dir1_jan19a      set dir2 dir2_jan19a      set ang1 ang1_jan19a      set ang2 ang2_jan19a      set dis1 dis1_jan19a      set dis2 dis2_jan19a ]
  if ( draw_year = 18 and draw_fortnight = 4 ) [ set con1 con1_jan19b      set con2 con2_jan19b      set dir1 dir1_jan19b      set dir2 dir2_jan19b      set ang1 ang1_jan19b      set ang2 ang2_jan19b      set dis1 dis1_jan19b      set dis2 dis2_jan19b ]

  if ( draw_year = 19 and draw_fortnight = 1 ) [ set con1 con1_dec19a      set con2 con2_dec19a      set dir1 dir1_dec19a      set dir2 dir2_dec19a      set ang1 ang1_dec19a      set ang2 ang2_dec19a      set dis1 dis1_dec19a      set dis2 dis2_dec19a ]
  if ( draw_year = 19 and draw_fortnight = 2 ) [ set con1 con1_dec19b      set con2 con2_dec19b      set dir1 dir1_dec19b      set dir2 dir2_dec19b      set ang1 ang1_dec19b      set ang2 ang2_dec19b      set dis1 dis1_dec19b      set dis2 dis2_dec19b ]
  if ( draw_year = 19 and draw_fortnight = 3 ) [ set con1 con1_jan20a      set con2 con2_jan20a      set dir1 dir1_jan20a      set dir2 dir2_jan20a      set ang1 ang1_jan20a      set ang2 ang2_jan20a      set dis1 dis1_jan20a      set dis2 dis2_jan20a ]
  if ( draw_year = 19 and draw_fortnight = 4 ) [ set con1 con1_jan20b      set con2 con2_jan20b      set dir1 dir1_jan20b      set dir2 dir2_jan20b      set ang1 ang1_jan20b      set ang2 ang2_jan20b      set dis1 dis1_jan20b      set dis2 dis2_jan20b ]

  if ( draw_year = 20 and draw_fortnight = 1 ) [ set con1 con1_dec20a      set con2 con2_dec20a      set dir1 dir1_dec20a      set dir2 dir2_dec20a      set ang1 ang1_dec20a      set ang2 ang2_dec20a      set dis1 dis1_dec20a      set dis2 dis2_dec20a ]
  if ( draw_year = 20 and draw_fortnight = 2 ) [ set con1 con1_dec20b      set con2 con2_dec20b      set dir1 dir1_dec20b      set dir2 dir2_dec20b      set ang1 ang1_dec20b      set ang2 ang2_dec20b      set dis1 dis1_dec20b      set dis2 dis2_dec20b ]
  if ( draw_year = 20 and draw_fortnight = 3 ) [ set con1 con1_jan21a      set con2 con2_jan21a      set dir1 dir1_jan21a      set dir2 dir2_jan21a      set ang1 ang1_jan21a      set ang2 ang2_jan21a      set dis1 dis1_jan21a      set dis2 dis2_jan21a ]
  if ( draw_year = 20 and draw_fortnight = 4 ) [ set con1 con1_jan21b      set con2 con2_jan21b      set dir1 dir1_jan21b      set dir2 dir2_jan21b      set ang1 ang1_jan21b      set ang2 ang2_jan21b      set dis1 dis1_jan21b      set dis2 dis2_jan21b ]

  if ( draw_year = 21 and draw_fortnight = 1 ) [ set con1 con1_dec21a      set con2 con2_dec21a      set dir1 dir1_dec21a      set dir2 dir2_dec21a      set ang1 ang1_dec21a      set ang2 ang2_dec21a      set dis1 dis1_dec21a      set dis2 dis2_dec21a ]
  if ( draw_year = 21 and draw_fortnight = 2 ) [ set con1 con1_dec21b      set con2 con2_dec21b      set dir1 dir1_dec21b      set dir2 dir2_dec21b      set ang1 ang1_dec21b      set ang2 ang2_dec21b      set dis1 dis1_dec21b      set dis2 dis2_dec21b ]
  if ( draw_year = 21 and draw_fortnight = 3 ) [ set con1 con1_jan22a      set con2 con2_jan22a      set dir1 dir1_jan22a      set dir2 dir2_jan22a      set ang1 ang1_jan22a      set ang2 ang2_jan22a      set dis1 dis1_jan22a      set dis2 dis2_jan22a ]
  if ( draw_year = 21 and draw_fortnight = 4 ) [ set con1 con1_jan22b      set con2 con2_jan22b      set dir1 dir1_jan22b      set dir2 dir2_jan22b      set ang1 ang1_jan22b      set ang2 ang2_jan22b      set dis1 dis1_jan22b      set dis2 dis2_jan22b ]

  let S_natal random-float ( exp ( -50 / sqrt ( reef_sites ) ) )                         ;; larval retention set by Jim Greenwood analysis relating reefs (with number of sites) to max retention time and min settling time (25 days)

  ask sites-here [ if ( ( S_2 + S_3 + S_4 + S_5 + S_6 ) > S_spawning_threshold ) [ set S_source S_source + Temp_y * ( S_2 + 2 * S_3 + 4 * S_4 + 8 * S_5 + 8 * S_6 ) ] ]     ;; spawning source is cumulative over all parts of reef where spawning threshold is exceeded

  ask sites-here [ set S_0 S_0 + random ( ( con1 + con2 ) * S_recruit * S_source * S_natal * R_site ) ]                                        ;; larval retention, CoTS can only recruit into areas without coral due to predation on larvae and damage inflicted on juveniles (Deaker et al. 2020)

  if ( dis1 > 0 )                                                                                                                              ;; first kernel
  [
    set heading dir1
    ask other reefs in-cone ( dis1 * per_km ) ang1
    [
      if ( ( distancexy x_source y_source ) < random-float ( dis1 * per_km ) )                                                                 ;; less likely to connect to reefs further away as sector arc widens linearly with distance
      [
        ask sites-here [ set S_0 min ( list ( S_0 + random ( con1 * S_recruit * S_source * ( 1 - S_natal ) * R_site ) ) 1000000 ) ]            ;; recruitment to rubble
      ]
    ]
  ]

  if ( dis2 > 0 )                                                                                                                              ;; second kernel
  [
    set heading dir2
    ask other reefs in-cone ( dis2 * per_km ) ang2
    [
      if ( ( distancexy x_source y_source ) < random-float ( dis2 * per_km ) )                                                                 ;; less likely to connect to reefs further away as sector arc widens linearly with distance
      [
        ask sites-here [ set S_0 min ( list ( S_0 + random ( con2 * S_recruit * S_source * ( 1 - S_natal ) * R_site ) ) 1000000 )  ]          ;; recruitment to rubble
      ]
    ]
  ]
end


to release-fish                                                                         ;; intervene by seeding a thermally tolerant coral on highest priority reefs
  random-seed ( ( ensemble + 1 ) * year )
  let p 0
  let treatments 0
;  let seed_fraction seed-hectares / seed-reefs / ha_per_site                           ;; fractional cover seeded at each site
  while [ treatments < release-reefs and p <= number_of_reefs ]
  [
    set p p + 1
    ask reefs with [ priority = p and x > intervene-lon-min and x < intervene-lon-max and y > intervene-lat-min and y < intervene-lat-max and ( E_2 + E_3 + E_4 + E_5 ) < release-threshold ]                   ;; seeding starts with highest priority reefs within intervention area with coral cover below threshold
    [
      set E_1 round ( E_1 + release-number / release-reefs / ( reef_sites * ha_per_site ) )
      set treatments treatments + 1
      set pcolor orange
    ]
  ]
end


to control-cots                                                                         ;; intervene by manually controlling CoTS on selected reefs using an ecological threshold
;  let manta_ratio 0.15                                                                 ;; fraction of adult CoTS detected by control program that is observed by a manta tow: 0.22 CoTS per manta tow ~ 15 CoTS per hectare
  random-seed ( ( ensemble + 1 ) * year )
  let dives_remaining 0.9 * 20 * 36 * 8 * S_vessels                                     ;; 0.9 time devoted to control x 20 voyages/year x 36 dive-sessions/voyage x 8 divers/vessel * vessels
  let dives_site 0
  let dives_total 0
  let diver_detect 1
  let p 0
  while [ dives_remaining > 0 and p <= number_of_reefs ]
  [
    set p p + 1                                                                         ;; note that all reefs have previously been prioritised from p = 1 to p = 3753 (random order except GBRMPA priority reefs came first)
    set dives_remaining dives_remaining - ( 1 * 8 )                                     ;; ensures loop completes and captures time lost in moving between reefs

    ask reefs with [ priority = p ]
;    ask reefs with [ priority = p and year < rezone_year and year < future_rezone_year ]
    [
      if ( ( region_name = control_region or control_region = "GBR" ) and ( S_manta_r < CoTS-threshold or C_reef > coral-threshold ) )
      [
;;      set eco_threshold ( 20 * ( C_sa_r + C_ta_r + C_mo_r + C_tt_r ) + 4 ) * manta_ratio         ;; ecological threshold (CPUE) derived from Plaganyi et al. (2019) in prep not currently used in field                                                                              ;; ecological threshold based on current (2018-) control program
        set dives_total 0
        ask sites-here with [ S_manta > eco-threshold ]                                 ;; site decision: based on ecological threshold
        [
;          set dives_remaining dives_remaining - ( ( 167 / 40 ) * ( ( S_2 + S_3 + S_4 + S_5 + S_6 ) / ( manta_ratio * 544 ) ) ^ 0.667 )
          set dives_site round ( ( 167 / 40 ) * S_manta ^ 0.667 )                       ;; based on Dan's regression for bottom time verses CoTS concentration (40 minute dives)
          set dives_remaining dives_remaining - dives_site
          set dives_total dives_total + dives_site
          set diver_detect 1.5 + random-float 0.5                                       ;; divers find 50-100% more CoTS than do manta tows
          set S_2 round ( 0.50 * eco-threshold / diver_detect )
          set S_3 round ( 0.30 * eco-threshold / diver_detect )                         ;; detectability increases with each age class according to MacNeil et al. (2016)
          set S_4 round ( 0.15 * eco-threshold / diver_detect )
          set S_5 round ( 0.05 * eco-threshold / diver_detect )
          set S_6 round ( 0.01 * eco-threshold / diver_detect )
          set S_1 round ( min ( list S_1 ( 2.77 * ( S_2 + S_3 + S_4 + S_5 + S_6 ) ) ) ) ;; 2.77 from  from Table 4 data in Plaganyi et al. (2019, in prep)
        ]
        set dives_reef dives_reef + dives_total
        set pcolor orange
      ]
    ]
  ]
end


to control-cots-by-sector                                                                 ;; intervene by manually controlling CoTS on selected reefs using an ecological threshold
  random-seed ( ( ensemble + 1 ) * year )
  let dives_remaining 0.9 * 20 * 36 * 8 * S_vessels                                       ;; 0.9 time devoted to control x 20 voyages/year x 36 dive-sessions/voyage x 8 divers/vessel * vessels
  let dives_site 0
  let dives_total 0
  let diver_detect 1
  let p 0
  let sector 0
  let S_manta_max 0
  let S_manta_new mean [ S_manta_r ] of reefs with [ sector_number = 1 ]
  if ( S_manta_new > S_manta_max ) [ set sector 1  set S_manta_max S_manta_new ]
  set S_manta_new mean [ S_manta_r ] of reefs with [ sector_number = 2 ]
  if ( S_manta_new > S_manta_max ) [ set sector 2  set S_manta_max S_manta_new ]
  set S_manta_new mean [ S_manta_r ] of reefs with [ sector_number = 3 ]
  if ( S_manta_new > S_manta_max ) [ set sector 3  set S_manta_max S_manta_new ]
  set S_manta_new mean [ S_manta_r ] of reefs with [ sector_number = 4 ]
  if ( S_manta_new > S_manta_max ) [ set sector 4  set S_manta_max S_manta_new ]
  set S_manta_new mean [ S_manta_r ] of reefs with [ sector_number = 5 ]
  if ( S_manta_new > S_manta_max ) [ set sector 5  set S_manta_max S_manta_new ]
  set S_manta_new mean [ S_manta_r ] of reefs with [ sector_number = 6 ]
  if ( S_manta_new > S_manta_max ) [ set sector 6  set S_manta_max S_manta_new ]
  set S_manta_new mean [ S_manta_r ] of reefs with [ sector_number = 7 ]
  if ( S_manta_new > S_manta_max ) [ set sector 7  set S_manta_max S_manta_new ]
  set S_manta_new mean [ S_manta_r ] of reefs with [ sector_number = 8 ]
  if ( S_manta_new > S_manta_max ) [ set sector 8  set S_manta_max S_manta_new ]
  set S_manta_new mean [ S_manta_r ] of reefs with [ sector_number = 9 ]
  if ( S_manta_new > S_manta_max ) [ set sector 9  set S_manta_max S_manta_new ]
  set S_manta_new mean [ S_manta_r ] of reefs with [ sector_number = 10 ]
  if ( S_manta_new > S_manta_max ) [ set sector 10  set S_manta_max S_manta_new ]
  set S_manta_new mean [ S_manta_r ] of reefs with [ sector_number = 11 ]
  if ( S_manta_new > S_manta_max ) [ set sector 11  set S_manta_max S_manta_new ]
  type "control sector" print sector

  while [ dives_remaining > 0 and p <= number_of_reefs ]
  [
    set p p + 1                                                                         ;; note that all reefs have previously been prioritised from p = 1 to p = 3753 (random order except GBRMPA priority reefs came first)
    set dives_remaining dives_remaining - ( 1 * 8 )                                     ;; ensures loop completes and captures time lost in moving between reefs
    ask reefs with [ priority = p and sector_number = sector ]
    [
      set dives_total 0
      ask sites-here with [ S_manta > eco-threshold ]                                 ;; site decision: based on ecological threshold
      [
        set dives_site round ( 0.7 * ( 167 / 40 ) * S_manta ^ 0.667 )                 ;; based on Dan's regression for bottom time verses CoTS concentration (40 minute dives) with 0.7 accounting for increased efficiency of recent control
        set dives_remaining dives_remaining - dives_site
        set dives_total dives_total + dives_site
        set diver_detect 1.5 + random-float 0.5                                       ;; divers find 50-100% more CoTS than do manta tows
        set S_2 round ( 0.50 * eco-threshold / diver_detect )
        set S_3 round ( 0.30 * eco-threshold / diver_detect )                         ;; detectability increases with each age class according to MacNeil et al. (2016)
        set S_4 round ( 0.15 * eco-threshold / diver_detect )
        set S_5 round ( 0.05 * eco-threshold / diver_detect )
        set S_6 round ( 0.01 * eco-threshold / diver_detect )
        set S_1 round ( min ( list S_1 ( 2.77 * ( S_2 + S_3 + S_4 + S_5 + S_6 ) ) ) ) ;; 2.77 from  from Table 4 data in Plaganyi et al. (2019, in prep)
      ]
      set dives_reef dives_reef + dives_total
      set pcolor orange
    ]
  ]
end


to consolidate-rubble                                                                   ;; intervene by consolidating coral rubble on selected reefs
  random-seed ( ( ensemble + 1 ) * year )
  let p 0
  let treatments 0
  while [ treatments < consolidation-reefs and p <= number_of_reefs ]
  [
    set p p + 1
    ask reefs with [ priority = p and x > intervene-lon-min and x < intervene-lon-max and y > intervene-lat-min and y < intervene-lat-max and R_reef > consolidation-threshold ]  ;; consolidation starts with highest priority reefs within latitude band
    [
      ask one-of sites-here with [ R_site > ( consolidation-hectares / ha_per_site ) ]     ;; one site treated on each reef each year
      [
        set R_site R_site - ( consolidation-hectares / ha_per_site )
        set treatments treatments + 1
        set pcolor blue
      ]
    ]
  ]
end


to seed-tt-coral                                                                           ;; intervene by seeding a thermally tolerant coral on highest priority reefs
  random-seed ( ( ensemble + 1 ) * year )
  let p 0
  let treatments 0
  let seed_fraction seed-hectares / seed-reefs / ha_per_site                               ;; fractional cover seeded at each site
  while [ treatments < seed-reefs and p <= number_of_reefs ]
  [
    set p p + 1
    ask reefs with [ priority = p and x > intervene-lon-min and x < intervene-lon-max and y > intervene-lat-min and y < intervene-lat-max and C_reef < seed-threshold ]                   ;; seeding starts with highest priority reefs within intervention area with coral cover below threshold
    [
      ask one-of sites-here with [ C_tt < seed_fraction and C_site < ( 1 - seed_fraction ) ]            ;; check that there is low pre-existing resistant coral and adequate space for seeding
      [
        set thermal_tt ( seed_fraction * thermal_tt_i + C_tt * thermal_tt ) / ( seed_fraction + C_tt + small )  ;; thermal tolerance is a weighted average of values for existing coral and new recruits
        set C_tt C_tt + seed_fraction
        set treatments treatments + 1
        set pcolor blue
      ]
    ]
  ]
end


to seed-coral-slick
  random-seed ( ( ensemble + 1 ) * year )
  let p 0
  let treatments 0
  let slick_fraction slick-hectares / slick-reefs / ha_per_site
  let fraction_sa 0
  let fraction_ta 0
  let fraction_mo 0
  let fraction_fa 0
  let fraction_po 0
  let fraction_tt 0
  let thermal_sa_slick 0
  let thermal_ta_slick 0
  let thermal_mo_slick 0
  let thermal_fa_slick 0
  let thermal_po_slick 0
  let thermal_tt_slick 0
  ask one-of sites                                                            ;; collect slick from another reef - currently random
  [
    set fraction_sa C_sa / C_site                                             ;; fraction of slick that is sa
    set fraction_ta C_ta / C_site
    set fraction_mo C_mo / C_site
    set fraction_fa C_fa / C_site
    set fraction_po C_po / C_site
    set fraction_tt C_tt / C_site
    set thermal_sa_slick thermal_sa
    set thermal_ta_slick thermal_ta
    set thermal_mo_slick thermal_mo
    set thermal_fa_slick thermal_fa
    set thermal_po_slick thermal_po
    set thermal_tt_slick thermal_tt
  ]
  while [ treatments < slick-reefs and p <= number_of_reefs ]
  [
    set p p + 1
    ask reefs with [ priority = p and x > intervene-lon-min and x < intervene-lon-max and y > intervene-lat-min and y < intervene-lat-max and C_tt_r < slick-threshold ]                   ;; slicking starts with highest priority reefs within intervention area with coral cover below threshold
    [
      ask one-of sites-here with [ C_site < ( 1 - slick_fraction ) ]            ;; check that there is adequate space for slicking
      [
        set thermal_sa ( slick_fraction * thermal_sa_slick + C_sa * thermal_sa ) / ( slick_fraction + C_sa )   ;; thermal tolerance is a weighted average of values for existing coral and new recruits
        set thermal_ta ( slick_fraction * thermal_ta_slick + C_ta * thermal_ta ) / ( slick_fraction + C_ta )
        set thermal_mo ( slick_fraction * thermal_mo_slick + C_mo * thermal_mo ) / ( slick_fraction + C_mo )
        set thermal_fa ( slick_fraction * thermal_fa_slick + C_fa * thermal_fa ) / ( slick_fraction + C_fa )
        set thermal_po ( slick_fraction * thermal_po_slick + C_po * thermal_po ) / ( slick_fraction + C_po )
        set thermal_tt ( slick_fraction * thermal_tt_slick + C_tt * thermal_tt ) / ( slick_fraction + C_tt )
        set C_sa C_sa + fraction_sa * slick_fraction
        set C_ta C_ta + fraction_ta * slick_fraction
        set C_mo C_mo + fraction_mo * slick_fraction
        set C_fa C_fa + fraction_fa * slick_fraction
        set C_po C_po + fraction_po * slick_fraction
        set C_tt C_tt + fraction_tt * slick_fraction
        set treatments treatments + 1
        set pcolor blue
      ]
    ]
  ]
end


to shade-local-reef                                                                                   ;; intervene by shading selected reefs
  random-seed ( ( ensemble + 1 ) * year )
  let p 0
  let treatments 0
  ask reefs [ set reef_shading 0 ]
  while [ treatments < shading-reefs and p <= number_of_reefs ]
  [
    set p p + 1
    ask reefs with [ priority = p and x > intervene-lon-min and x < intervene-lon-max and y > intervene-lat-min and y < intervene-lat-max ]    ;; shading starts with highest priority reefs within latitude band
    [
      set reef_shading reef-shading-reduction
      set treatments treatments + 1
      set pcolor blue
    ]
  ]
end


to shade-regional-coral
  random-seed ( ( ensemble + 1 ) * year )
  ask reefs [ set regional_shading 0 ]
  ask reefs with [ x > intervene-lon-min and x < intervene-lon-max and y > intervene-lat-min and y < intervene-lat-max ]                       ;; shading within latitude band
  [
    set regional_shading regional-shading-reduction
  ]
end


to increase-pH                                                                                   ;; intervene by artifically increasing the pH on selected reefs
  random-seed ( ( ensemble + 1 ) * year )
  let p 0
  let treatments 0
  while [ treatments < pH-reefs and p <= number_of_reefs ]                                       ;; seeding applied to seeded-reefs number of reefs
  [
    set p p + 1
    ask reefs with [ priority = p and x > intervene-lon-min and x < intervene-lon-max and y > intervene-lat-min and y < intervene-lat-max ]    ;; increase in pH starts with highest priority reefs within latitude band
    [
      set pH_protect pH-protection
      set treatments treatments + 1
      set pcolor blue
    ]
  ]
end


to bleaching                                                                            ;; expose reefs to a bleaching event
  random-seed ( ( ensemble + 1 ) * year )
  let rand 0
  let dhw_max 0                                                                         ;; bleaching formulation based on degree heating weeks (dhw)
  let dhw_reef 0                                                                        ;; dhw applied across sites on a reef
  let bleaching_centre 0
  let bleaching_radius 0
  let radial_decline 0

  ask reefs
  [
    set dhw 0
    ask sites-here
    [
      set bleach_mort_sa 0
      set bleach_mort_ta 0
      set bleach_mort_mo 0
      set bleach_mort_po 0
      set bleach_mort_fa 0
      set bleach_mort_tt 0
    ]
  ]

  if ( year > 1997 and year < projection-year )                                        ;; apply historical bleaching events
  [
    if ( year = 1998 )
    [
      set dhw_max 8                                ;; from Hughes et al. 2017 fig.1
      ask one-of reefs with [ y > -21 and y < -20 ] [ set bleaching_centre who ]
    ]
    if ( year = 2002 )
    [
      set dhw_max 10                               ;; from Hughes et al. 2017 fig.1
      ask one-of reefs with [ y > -21 and y < -20 ] [ set bleaching_centre who ]
    ]
    if ( year = 2016 )
    [
      set dhw_max 9 ;10                               ;; from Hughes et al. 2017 fig.1
      ask one-of reefs with [ y > -12 and y < -11 ] [ set bleaching_centre who ]
    ]
    if ( year = 2017 )
    [
      set dhw_max 8  ;9
      ask one-of reefs with [ y > -17 and y < -16 ] [ set bleaching_centre who ]
    ]
    if ( year = 2020 )
    [
      set dhw_max 6 ;7
      ask one-of reefs with [ y > -20 and y < -19 ] [ set bleaching_centre who ]
    ]
    if ( year = 2022 )
    [
      set dhw_max 6 ;7
      ask one-of reefs with [ y > -18 and y < -17 ] [ set bleaching_centre who ]
    ]
  ]
  if ( year >= projection-year )                   ;; bleaching applied randomly
  [
    random-seed ( ( ensemble + 1 ) * year )                                                             ;; ensures ensembles are repeatable and comparable (in terms of climate forcing)
    if ( SSP = 1.9 ) [ set dhw_max ( 8 - random-float ( 16 ) ) - 0.0028 * ( year - 2060 ) ^ 2 + 8 ]      ;; random variability based on McWhorter et al. (2022)
    if ( SSP = 2.6 ) [ set dhw_max ( 8 - random-float ( 16 ) ) - 0.0026 * ( year - 2070 ) ^ 2 + 10 ]
    if ( SSP = 4.5 ) [ set dhw_max ( 8 - random-float ( 16 ) ) + 0.221 * year - 444 ]
    if ( SSP = 7.0 ) [ set dhw_max ( 8 - random-float ( 16 ) ) + 0.0039 * ( year - 2010 ) ^ 2 + 2 ]
    if ( SSP = 8.5 ) [ set dhw_max ( 8 - random-float ( 16 ) ) + 0.0047 * ( year - 2000 ) ^ 2 + 1 ]
    ask one-of reefs [ set bleaching_centre who ]                                                        ;; locations of bleaching events are random over the projection period
  ]

  if ( dhw_max > 0 )
  [
    if ( dhw_max >= 8 ) [ type year type " mass bleaching " type round ( dhw_max ) print " DHW" ]
    set bleaching_radius dhw_scale * dhw_max * ( 0.5 + random-float 1.0 )
;    print bleaching_radius
    ask reef bleaching_centre
    [
      ask reefs in-radius bleaching_radius
      [
        set radial_decline 1 - median ( list 0 ( ( ( distance reef bleaching_centre ) / per_km / bleaching_radius ) ^ 2 ) 1 )     ;; radial scale of bleaching event (km) is 10 to 20 times dhw_max
        set rand ( 0.5 + random-float 0.5 ) * radial_decline
        set dhw dhw_max * radial_decline * ( 1 - reef_shading ) * ( 1 - regional_shading )
        set dhw_reef dhw
        if ( dhw > 8 ) [ set pcolor red ]
        ask sites-here
        [
          set rand random-float ( 1.0 )
;          set rand 0.5 + random-float ( 0.5 )                                                                              ;; maximum possible mortality, coral groups at the same site have correlated mortality
          let new_rubble 0

          set bleach_mort_sa max ( list 0 ( rand * ( 1 - exp ( -0.12 * ( dhw_reef - thermal_sa ) ) ) ) )
;          set bleach_mort_sa max ( list 0 ( rand * ( 1 - exp ( -0.01 * exp ( 0.3 * ( dhw_reef - thermal_sa ) ) ) ) ) )     ;; Gompertz function [ 0.1 1.0 ], note thermal_sa belongs to site
          set new_rubble 2 * C_sa * bleach_mort_sa                                                                         ;; add rubble due to bleaching, factor of 2 account for a hemisphere of dead coral to spread into a layer of rubble
          set C_sa C_sa * ( 1 - bleach_mort_sa )                                                                           ;; bleaching
          set thermal_sa thermal_sa * ( ( 1 + adaptability ) ^ bleach_mort_sa )                                            ;; exposure increases thermal tolerance of surviving coral
          set thermal_sa min ( list thermal_sa ( thermal_sa_i + adapt_plasticity ) )                                       ;; limit adaptation to max_plasticity DHW

          set bleach_mort_ta max ( list 0 ( rand * ( 1 - exp ( -0.12 * ( dhw_reef - thermal_ta ) ) ) ) )
;          set bleach_mort_ta max ( list 0 ( rand * ( 1 - exp ( -0.01 * exp ( 0.3 * ( dhw_reef - thermal_ta ) ) ) ) ) )     ;; Gompertz function
          set new_rubble new_rubble + 2 * C_ta * bleach_mort_ta
          set C_ta C_ta * ( 1 - bleach_mort_ta )
          set thermal_ta thermal_ta * ( ( 1 + adaptability ) ^ bleach_mort_ta )
          set thermal_ta min ( list thermal_ta ( thermal_ta_i + adapt_plasticity ) )

          set bleach_mort_mo max ( list 0 ( rand * ( 1 - exp ( -0.12 * ( dhw_reef - thermal_mo ) ) ) ) )
;          set bleach_mort_mo max ( list 0 ( rand * ( 1 - exp ( -0.01 * exp ( 0.3 * ( dhw_reef - thermal_mo ) ) ) ) ) )     ;; Gompertz function
          set new_rubble new_rubble + 2 * C_mo * bleach_mort_mo
          set C_mo C_mo * ( 1 - bleach_mort_mo )
          set thermal_mo thermal_mo * ( ( 1 + adaptability ) ^ bleach_mort_mo )
          set thermal_mo min ( list thermal_mo ( thermal_mo_i + adapt_plasticity ) )

          set bleach_mort_po max ( list 0 ( rand * ( 1 - exp ( -0.12 * ( dhw_reef - thermal_po ) ) ) ) )
;          set bleach_mort_po max ( list 0 ( rand * ( 1 - exp ( -0.01 * exp ( 0.3 * ( dhw_reef - thermal_po ) ) ) ) ) )     ;; Gompertz function
          set new_rubble new_rubble + 2 * C_po * bleach_mort_po
          set C_po C_po * ( 1 - bleach_mort_po )
          set thermal_po thermal_po * ( ( 1 + adaptability ) ^ bleach_mort_po )
          set thermal_po min ( list thermal_po ( thermal_po_i + adapt_plasticity ) )

          set bleach_mort_fa max ( list 0 ( rand * ( 1 - exp ( -0.12 * ( dhw_reef - thermal_fa ) ) ) ) )
;          set bleach_mort_fa max ( list 0 ( rand * ( 1 - exp ( -0.01 * exp ( 0.3 * ( dhw_reef - thermal_fa ) ) ) ) ) )     ;; Gompertz function
          set new_rubble new_rubble + 2 * C_fa * bleach_mort_fa
          set C_fa C_fa * ( 1 - bleach_mort_fa )
          set thermal_fa thermal_fa * ( ( 1 + adaptability ) ^ bleach_mort_fa )
          set thermal_fa min ( list thermal_fa ( thermal_fa_i + adapt_plasticity ) )

          set bleach_mort_tt max ( list 0 ( rand * ( 1 - exp ( -0.12 * ( dhw_reef - thermal_tt ) ) ) ) )
;          set bleach_mort_tt max ( list 0 ( rand * ( 1 - exp ( -0.01 * exp ( 0.3 * ( dhw_reef - thermal_tt ) ) ) ) ) )     ;; Gompertz function
          set new_rubble new_rubble + 2 * C_tt * bleach_mort_tt
          set C_tt C_tt * ( 1 - bleach_mort_tt )
          set thermal_tt thermal_tt * ( ( 1 + adaptability ) ^ bleach_mort_tt )
          set thermal_tt min ( list thermal_tt ( thermal_tt_i + adapt_plasticity ) )

          set R_site min ( list 1.0 ( R_site + new_rubble ) )

          set thermal_sa thermal_sa - ( thermal_sa - thermal_sa_i ) / ( adapt_decay_time )                                 ;; without thermal pressure, thermal tolerance tends to decay towards its initial value
          set rate_sa rate_sa_i * ( 1 - adapt_penalty * ( thermal_sa - thermal_sa_i ) )                                    ;; modest decline in growth rate associated with higher thermal tolerance, no change from initial value while thermal_f = 1
          set thermal_ta thermal_ta - ( thermal_ta - thermal_ta_i ) / ( adapt_decay_time / ( ( rate_ta + small ) / ( rate_sa + small ) ) )
          set rate_ta rate_ta_i * ( 1 - adapt_penalty * ( thermal_ta - thermal_ta_i ) )
          set thermal_mo thermal_mo - ( thermal_mo - thermal_mo_i ) / ( adapt_decay_time / ( ( rate_mo + small ) / ( rate_sa + small ) ) )
          set rate_mo rate_mo_i * ( 1 - adapt_penalty * ( thermal_mo - thermal_mo_i ) )
          set thermal_po thermal_po - ( thermal_po - thermal_po_i ) / ( adapt_decay_time / ( ( rate_po + small ) / ( rate_sa + small ) ) )
          set rate_po rate_po_i * ( 1 - adapt_penalty * ( thermal_po - thermal_po_i ) )
          set thermal_fa thermal_fa - ( thermal_fa - thermal_fa_i ) / ( adapt_decay_time / ( ( rate_fa + small ) / ( rate_sa + small ) ) )
          set rate_fa rate_fa_i * ( 1 - adapt_penalty * ( thermal_fa - thermal_fa_i ) )
          set thermal_tt thermal_tt - ( thermal_tt - thermal_tt_i ) / ( adapt_decay_time / ( ( rate_tt + small ) / ( rate_sa + small ) ) )
          set rate_tt rate_tt_i * ( 1 - adapt_penalty * ( thermal_tt - thermal_tt_i ) )                                   ;; lower growth rate (initially 77%) associated with higher thermal tolerance
        ]
      ]
    ]
  ]
end


to cyclone                                                       ;; expose reefs to a tropical cyclone event
  random-seed ( ( ensemble + 1 ) * year )                        ;; ensures ensembles are repeatable and comparable (in terms of climate forcing)

  let smaller ( 200 + random 300 ) * per_km
  let medium ( 400 + random 300 ) * per_km
  let larger ( 600 + random 300 ) * per_km

  ask reefs
  [
    ask sites-here
    [
      set cyclone_mort_sa 0
      set cyclone_mort_ta 0
      set cyclone_mort_mo 0
      set cyclone_mort_po 0
      set cyclone_mort_fa 0
      set cyclone_mort_tt 0
    ]
  ]

  if ( random 100 < 35 )                                                           ;; category 2 storms applied randomly in all years - probability increased from 29% to 35% to include smaller storms
  [
    set cyclone_category 2
    set cyclone_radius smaller                                                    ;; category 2 storms have average radius of 150 km
    ask one-of reefs [ set cyclone_centre who ]
    cyclone-mortality
  ]

  ifelse ( year > 1975 and year < projection-year )                                ;; apply historical cyclones of category 3, 4 or 5
  [
    if ( year = 1976 )
    [
      type year print " Cyclone David"
      set cyclone_radius smaller      ;; guess
      set cyclone_category 3
      ask one-of reefs with [ y > -23 and y < -22 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( year = 1980 )
    [
      type year print " Cyclone Simon"
      set cyclone_radius smaller       ;; guess
      set cyclone_category 4
      ask one-of reefs with [ y > -23 and y < -22 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( year = 1986 )
    [
      type year print " Cyclone Winifred"
      set cyclone_radius medium       ; was 204
      set cyclone_category 3
      ask one-of reefs with [ y > -18 and y < -17 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( year = 1989 )
    [
      type year print " Cyclone Aivu"
      set cyclone_radius larger      ; was 269
      set cyclone_category 3
      ask one-of reefs with [ y > -20 and y < -19 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( year = 1990 )
    [
      type year print " Cyclone Ivor"
      set cyclone_radius medium     ;; guess
      set cyclone_category 3
      ask one-of reefs with [ y > -15 and y < -14 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( year = 1991 )
    [
      type year print " Cyclone Joy"
      set cyclone_radius larger     ; was 206
      set cyclone_category 4
      ask one-of reefs with [ y > -18 and y < -17 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( year = 1997 )
    [
      type year print " Cyclone Justin"
      set cyclone_radius larger     ;; guess
      set cyclone_category 3
      ask one-of reefs with [ y > -19 and y < -18 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]

    if ( year = 1998 )
    [
      type year print " Cyclone Katrina"
      set cyclone_radius larger            ;; guess
      set cyclone_category 3
      ask one-of reefs with [ y > -16 and y < -15 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( year = 2005 )
    [
      type year print " Cyclone Ingrid"
      set cyclone_radius smaller            ;; was 120
      set cyclone_category 5
      ask one-of reefs with [ y > -14 and y < -13 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( year = 2006 )
    [
      type year print " Cyclone Larry"
      set cyclone_radius medium            ;; was 159
      set cyclone_category 3
      ask one-of reefs with [ y > -18 and y < -17 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( year = 2007 )
    [
      type year print " Cyclone Monica"
      set cyclone_radius smaller             ;; was 140
      set cyclone_category 3
      ask one-of reefs with [ y > -14 and y < -13 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( year = 2009 )
    [
      type year print " Cyclone Hamish"
      set cyclone_radius larger               ;; radius increased from 217 km to simulate path parallel to coast
      set cyclone_category 4  ;5              ;; reduce category because it stayed offshore
      ask one-of reefs with [ y > -21 and y < -20 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( year = 2010 )
    [
      type year print " Cyclone Ului"
      set cyclone_radius smaller                    ;; was 148
      set cyclone_category 3
      ask one-of reefs with [ y > -20 and y < -19 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( year = 2011 )
    [
      type year print " Cyclone Yassi"
      set cyclone_radius larger                       ;; was 180
      set cyclone_category 5
      ask one-of reefs with [ y > -18 and y < -17 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( year = 2014 )
    [
      type year print " Cyclone Ita"
      set cyclone_radius medium                    ;   was 167
      set cyclone_category 3 ;4
      ask one-of reefs with [ y > -15 and y < -14 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( year = 2015 )
    [
      type year print " Cyclone Marcia"
      set cyclone_radius smaller                    ;   was 154
      set cyclone_category 3 ;4
      ask one-of reefs with [ y > -22 and y < -20 ] [ set cyclone_centre who ]    ;; wider latitude range because Marcia ran parallel to coast
      cyclone-mortality
    ]
    if ( year = 2017 )
    [
      type year print " Cyclone Debbie"
      set cyclone_radius smaller                     ;; guess
      set cyclone_category 3 ;4
      ask one-of reefs with [ y > -20 and y < -19 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( year = 2019 )
    [
      type year print " Cyclone Trevor"
      set cyclone_radius smaller                    ;; guess
      set cyclone_category 3
      ask one-of reefs with [ y > -16 and y < -15 ] [ set cyclone_centre who ]
      cyclone-mortality
    ]
  ]

  [                                                                                ;; category 3, 4 and 5 cyclones applied randomly before 1976 and after 2022
    if ( random 100 < 21 )                                                         ;; category 3
    [
      type year print " category 3 cyclone"
      set cyclone_radius ( 200 + random 500 ) * per_km
      set cyclone_category 3
      ask one-of reefs [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( random 100 < 4 )                                                          ;; category 4
    [
      type year print " category 4 cyclone"
      set cyclone_radius ( 200 + random 600 ) * per_km
      set cyclone_category 4
      ask one-of reefs [ set cyclone_centre who ]
      cyclone-mortality
    ]
    if ( random 100 < 2 )                                                          ;; category 5
    [
      type year print " category 5 cyclone"
      set cyclone_radius ( 200 + random 700 ) * per_km
      set cyclone_category 5
      ask one-of reefs [ set cyclone_centre who ]
      cyclone-mortality
    ]
  ]

  set flood_load 0.2 + 0.4 * ( 1 + 0.2 * cyclone_category - catchment_condition )  ;; [ 0.2 1 ]
end


to cyclone-mortality
  random-seed ( ( ensemble + 1 ) * year )                        ;; ensures ensembles are repeatable and comparable (in terms of climate forcing)
  let rand 0
  let radial_decline 0
  let cyclone_mort_max 0
  let cyclone_mort_min 0

  ask reef cyclone_centre
  [
    ask patches in-radius cyclone_radius [ set pcolor grey ]
;    print cyclone_radius
    ask reefs in-radius cyclone_radius
    [
      set radial_decline 1 - median ( list 0 ( ( ( distance reef cyclone_centre ) / per_km / cyclone_radius ) ^ 2 ) 1 )
      let sheltering sqrt ( reef_sites * number_of_reefs / number_of_sites )
      ask sites-here
      [
        ;; test
        set rand ( 0.7 + random-float 0.3 ) * radial_decline / sheltering

        set cyclone_mort_max rand * ( 0.25 * cyclone_category - 0.30 )                   ;; damage levels differentiated by empirical studies (Guillemot et al. 2010) with no OA effect for cat 2
        set cyclone_mort_min rand * max ( list 0 ( 0.3 * cyclone_category - 0.9 ) )
        set cyclone_mort_sa ( 1.0 * cyclone_mort_max + 0.0 * cyclone_mort_min ) * ( rate_sa_i / rate_sa )
        set cyclone_mort_ta ( 0.9 * cyclone_mort_max + 0.1 * cyclone_mort_min ) * ( rate_ta_i / rate_ta )
        set cyclone_mort_mo ( 0.7 * cyclone_mort_max + 0.3 * cyclone_mort_min ) * ( rate_mo_i / rate_mo )
        set cyclone_mort_po ( 0.1 * cyclone_mort_max + 0.9 * cyclone_mort_min ) * ( rate_po_i / rate_po )
        set cyclone_mort_fa ( 0.0 * cyclone_mort_max + 1.0 * cyclone_mort_min ) * ( rate_fa_i / rate_fa )
        set cyclone_mort_tt ( 1.0 * cyclone_mort_max + 0.0 * cyclone_mort_min ) * ( rate_tt_i / rate_tt )
        set R_site median ( list 0.0 1.0 ( R_site + 2 * ( cyclone_mort_sa * C_sa + cyclone_mort_ta * C_ta + cyclone_mort_mo * C_mo + cyclone_mort_po * C_po + cyclone_mort_fa * C_fa + cyclone_mort_tt * C_tt ) ) )    ;; factor of 2 account for a hemisphere of dead coral to spread into a layer of rubble
        set C_sa C_sa * max ( list small ( 1 - cyclone_mort_sa ) )                       ;; always leave remnant corals
        set C_ta C_ta * max ( list small ( 1 - cyclone_mort_ta ) )
        set C_mo C_mo * max ( list small ( 1 - cyclone_mort_mo ) )
        set C_po C_po * max ( list small ( 1 - cyclone_mort_po ) )
        set C_fa C_fa * max ( list small ( 1 - cyclone_mort_fa ) )
        set C_tt C_tt * max ( list small ( 1 - cyclone_mort_tt ) )
      ]
    ]
  ]
end


to reef-populations                                                                     ;; calculate average reef populations from individual site populations
  ask sites
  [
    if ( B < 0 or B > B_max ) [ print "Error: B out of range" ]
    if ( T < 0 or T > T_max ) [ print "Error: T out of range" ]
    if ( S_1 < 0 or S_2 < 0 or S_3 < 0 or S_4 < 0 or S_6 < 0 ) [ print "Error: S negative" ]
    if ( C_sa < 0 or C_sa > 1 ) [ print "Error: C_sa out of range" ]
    if ( C_ta < 0 or C_ta > 1 ) [ print "Error: C_ta out of range" ]
    if ( C_mo < 0 or C_mo > 1 ) [ print "Error: C_mo out of range" ]
    if ( C_po < 0 or C_po > 1 ) [ print "Error: C_po out of range" ]
    if ( C_fa < 0 or C_fa > 1 ) [ print "Error: C_fa out of range" ]
    if ( C_tt < 0 or C_tt > 1 ) [ print "Error: C_tt out of range" ]
    if ( C_site < 0 or C_site > 1 ) [ print "Error: C_site out of range" ]
    if ( R_site < 0 or R_site > 1 ) [ print "Error: R_site out of range" ]
  ]
  ask reefs
  [
    if ( E_1 < 0 or E_2 < 0 or E_3 < 0 or E_4 < 0 or E_5 < 0 ) [ print "Error: E negative" ]
    if ( G_1 < 0 or G_2 < 0 or G_3 < 0 or G_4 < 0 or G_5 < 0 ) [ print "Error: G negative" ]
  ]

  ask reefs
  [
    set B_r round ( mean [ B ] of sites-here )
    set T_r round ( mean [ T ] of sites-here )

    set S_2_r round ( mean [ S_2 ] of sites-here )                                      ;; units of CoTS per ha
    set S_3_r round ( mean [ S_3 ] of sites-here )
    set S_4_r round ( mean [ S_4 ] of sites-here )
    set S_5_r round ( mean [ S_5 ] of sites-here )
    set S_6_r round ( mean [ S_6 ] of sites-here )
    set S_1_r round ( min ( list S_1_r ( 2.77 * ( S_2_r + S_3_r + S_4_r + S_5_r + S_6_r ) ) ) )       ;; 2.77 from  from Table 4 data in Plaganyi et al. (2019, in prep)
    set S_manta_r round ( 0.50 * S_2_r + 0.70 * S_3_r + 0.85 * S_4_r + 0.95 * S_5_r + 0.99 * S_6_r )  ;; manta tows detect on a fraction of CoTS

    set C_sa_r mean [ C_sa ] of sites-here
    set C_ta_r mean [ C_ta ] of sites-here
    set C_mo_r mean [ C_mo ] of sites-here
    set C_po_r mean [ C_po ] of sites-here
    set C_fa_r mean [ C_fa ] of sites-here
    set C_tt_r mean [ C_tt ] of sites-here
    set C_reef mean [ C_site] of sites-here
    set R_reef mean [ R_site ] of sites-here

    set bleach_mort_sa_r mean [ bleach_mort_sa ] of sites-here
    set bleach_mort_ta_r mean [ bleach_mort_ta ] of sites-here
    set bleach_mort_mo_r mean [ bleach_mort_mo ] of sites-here
    set bleach_mort_po_r mean [ bleach_mort_po ] of sites-here
    set bleach_mort_fa_r mean [ bleach_mort_fa ] of sites-here
    set bleach_mort_tt_r mean [ bleach_mort_tt ] of sites-here

    set cyclone_mort_sa_r mean [ cyclone_mort_sa ] of sites-here
    set cyclone_mort_ta_r mean [ cyclone_mort_ta ] of sites-here
    set cyclone_mort_mo_r mean [ cyclone_mort_mo ] of sites-here
    set cyclone_mort_po_r mean [ cyclone_mort_po ] of sites-here
    set cyclone_mort_fa_r mean [ cyclone_mort_fa ] of sites-here
    set cyclone_mort_tt_r mean [ cyclone_mort_tt ] of sites-here

    set predate_mort_sa_r mean [ predate_mort_sa ] of sites-here
    set predate_mort_ta_r mean [ predate_mort_ta ] of sites-here
    set predate_mort_mo_r mean [ predate_mort_mo ] of sites-here
    set predate_mort_po_r mean [ predate_mort_po ] of sites-here
    set predate_mort_fa_r mean [ predate_mort_fa ] of sites-here
    set predate_mort_tt_r mean [ predate_mort_tt ] of sites-here
  ]
  if ( search-mode = 1 and year >= search-year )
  [
    ask reefs with [ priority = 1 ] [ set benefit benefit + mean [ C_site ] of sites ]  ;; GBR-wide benefit of intervention at a single reef accumulating each year
  ]
end


to monitor-cots-coral                                                                   ;; monitor the reef specified in the GUI
  ask reef monitored_reef_number
  [
    set monitor_S_adult round ( ( S_2_r + S_3_r + S_4_r + S_5_r + S_6_r ) / 68 )        ;; factor of 68 converts to CoTS per manta tow
    set monitor_C_total ( C_sa_r + C_ta_r + C_mo_r + C_po_r + C_fa_r + C_tt_r )
    set monitor_C_tt C_tt_r
    set color red
  ]
end


to update-network-image                                                                  ;; update map image in GUI
  if Network-image-shows = "Coral (fast growing)" [ set color 29.9 - ( C_sa_r + C_ta_r + C_mo_r ) * 5.9 ]
  if Network-image-shows = "Coral (slow growing)" [ set color 129.9 - ( C_po_r + C_fa_r ) * 5.9 ]
  if Network-image-shows = "Coral (resistant)" [ set color 29.9 - C_tt_r * 5.9 ]
  if Network-image-shows = "CoTS (adult)"
  [
    set color 109.9 - ( S_2_r + S_3_r + S_4_r + S_5_r + S_6_r ) * 5.9 / 68
    if ( S_2_r + S_3_r + S_4_r + S_5_r + S_6_r < 15 ) [ set color 109.9 ]
  ]
end


to set-up-output-files                                                                  ;; set up output file containing all key variables on all reefs
  random-seed ( 1 )
  if (file-exists? output-filename)                                                     ;; Delete file if file already exists
  [ carefully
    [
      file-close
      file-delete output-filename
    ]
    [ print error-message ]
  ]
  file-open output-filename                                                            ;; Create file for all individual reef outputs
  file-type "Climate scenario" file-type ", " file-print SSP

  file-print ""
  file-type "Ensemble runs" file-type ", " file-print ensemble-runs
  file-type "Start year" file-type ", " file-print start-year
  file-type "Save year" file-type ", " file-print save-year
  file-type "Projection year" file-type ", " file-print projection-year
  file-type "End year" file-type ", " file-print end-year
  file-type "Search year" file-type ", " file-print search-year

  file-print ""
  file-type "CoTS control start year" file-type ", " file-print start-CoTS-control
  file-type "CoTS control ecological threshold (CoTS per ha)" file-type ", " file-print eco-threshold
  file-type "CoTS control CoTS threshold (CoTS per ha)" file-type ", " file-print CoTS-threshold
  file-type "CoTS control coral threshold (CoTS per ha)" file-type ", " file-print coral-threshold
  file-type "CoTS vessels across GBR" file-type ", " file-print CoTS-vessels-GBR
  file-type "CoTS vessels in Far-northern Region" file-type ", " file-print CoTS-vessels-FN
  file-type "CoTS vessels in Northern Region" file-type ", " file-print CoTS-vessels-N
  file-type "CoTS vessels in Central Region" file-type ", " file-print CoTS-vessels-C
  file-type "CoTS vessels in Southern Region" file-type ", " file-print CoTS-vessels-S

  file-type "Catchment restoration start year" file-type ", " file-print start-catchment-restore
  file-type "Catchment restoration timescale (years)" file-type ", " file-print restore-timeframe

  file-type "Future zoning start year" file-type ", " file-print start-modified-zoning
  file-type "Number of reefs included in future rezoning" file-type ", " file-print rezoned-reefs
  file-print ""
  file-type "Reduction in fisheries catch start year" file-type ", " file-print start-modified-fishing
  file-type " Fractional reduction in fisheries catches" file-type ", " file-print catch-reduction
  file-print ""
  file-type "Upper fish size limit start year" file-type ", " file-print start-upper-sizelimit
  file-type "Lower fish size limit start year" file-type ", " file-print start-lower-sizelimit
  file-type "Exclude fishing from active outbreak reefs start year" file-type ", " file-print start-CoTSlimit
  file-print ""
  file-type "Emperor release start year" file-type ", " file-print start-emperor-release
  file-type "Number of release reefs" file-type ", " file-print release-reefs
  file-type "Maximum adult emperors (per ha) for release" file-type ", " file-print release-threshold
  file-type "Number of juvenile emperors released per reef" file-type ", " file-print release-number

  file-print ""
  file-type "Regional shading start year" file-type ", " file-print start-regional-shading
  file-type "Absolute DHW reduction due to regional shading (DHW)" file-type ", " file-print regional-shading-reduction

  file-print ""
  file-type "Minimum longitude of interventions" file-type ", " file-print intervene-lon-min
  file-type "Maximum longitude of interventions" file-type ", " file-print intervene-lon-max
  file-type "Minimum latitude of interventions" file-type ", " file-print intervene-lat-min
  file-type "Maximum latitude of interventions" file-type ", " file-print intervene-lat-max
  file-print ""
  file-type "Rubble consolidation start year" file-type ", " file-print start-rubble-consolidation
  file-type "Annual number of consolidated reefs" file-type ", " file-print consolidation-reefs
  file-type "Minimum rubble cover threshold for consolidation [0 1]" file-type ", " file-print consolidation-threshold
  file-type "Total annual consolidated area (ha) " file-type ", " file-print consolidation-hectares
  file-print ""
  file-type "Thermally tolerant coral seeding start year" file-type ", " file-print start-coral-seeding
  file-type "Annual number of reefs seeded with coral" file-type ", " file-print seed-reefs
  file-type "Maximum coral cover threshold for coral seeding [0 1]" file-type ", " file-print seed-threshold
  file-type "Total annual area of seeded corals (ha)" file-type ", " file-print seed-hectares
  file-type "Fraction of staghorn acropora corals able to hybridise with thermally tolerant corals [0 1]" file-type ", " file-print hybrid-fraction
  file-type "Dominance of thermally tolerant corals in setting thermal tolerance of hybrids [0 1]" file-type ", " file-print dominance
  file-print ""
  file-type "Coral slicks start year" file-type ", " file-print start-coral-slick
  file-type "Annual number of reefs with coral slicks released" file-type ", " file-print seed-reefs
  file-type "Maximum coral cover threshold for coral slicks [0 1]" file-type ", " file-print seed-threshold
  file-type "Total annual area of slick corals (ha)" file-type ", " file-print seed-hectares
  file-print ""
  file-type "Reef shading start year" file-type ", " file-print start-reef-shading
  file-type "Annual number of reefs locally shaded" file-type ", " file-print shading-reefs
  file-type "Fractional DHW reduction due to local shading [0 1]" file-type ", " file-print reef-shading-reduction
  file-print ""
  file-type "Ocean acidification treatment start year" file-type ", " file-print start-pH-protection
  file-type "Annual number of reefs treated for ocean acidification" file-type ", " file-print pH-reefs
  file-type "Fractional protection from ocean acidification [0 1]" file-type ", " file-print pH-protection
  file-print ""
  file-type "Ensemble" file-type ", " file-type "Year" file-type ", " file-type "Reef_ID" file-type  ", " file-type "Region" file-type  ", " file-type "Shelf_position" file-type ", " file-type "Rezone_year" file-type ", " file-type "Priority" file-type ", " file-type "Longitude" file-type ", " file-type "Latitude" file-type ", " file-type "km_offshore" file-type ", " file-type "Reef_sites" file-type ","
  file-type "C_sa" file-type ", " file-type "C_ta" file-type ", " file-type "C_mo" file-type ", " file-type "C_po" file-type ", " file-type "C_fa" file-type ", " file-type "C_tt" file-type ", "
  file-type "C_out_degree" file-type ", "
  file-type "DHW" file-type ", "
  file-type "bleach_sa" file-type ", " file-type "bleach_ta" file-type ", " file-type "bleach_mo" file-type ", " file-type "bleach_po" file-type ", " file-type "bleach_fa" file-type ", " file-type "bleach_tt" file-type ", "
  file-type "Maximum_cyclone_category" file-type ", "
  file-type "cyclone_sa" file-type ", " file-type "cyclone_ta" file-type ", " file-type "cyclone_mo" file-type ", " file-type "cyclone_po" file-type ", " file-type "cyclone_fa" file-type ", " file-type "cyclone_tt" file-type ", "
  file-type "predate_sa" file-type ", " file-type "predate_ta" file-type ", " file-type "predate_mo" file-type ", " file-type "predate_po" file-type ", " file-type "predate_fa" file-type ", " file-type "predate_tt" file-type ", "
  file-type "S_1" file-type ", " file-type "S_2" file-type ", " file-type "S_3" file-type ", " file-type "S_4" file-type ", " file-type "S_5" file-type ", " file-type "S_6" file-type ", " file-type "S_manta" file-type ", "
  file-type "Control_dives" file-type ", "
  file-type "Benthic_invert" file-type ", " file-type "Triggerfish" file-type ", "
  file-type "E_1" file-type ", " file-type "E_2" file-type ", " file-type "E_3" file-type ", " file-type "E_4" file-type ", " file-type "E_5" file-type ", "
  file-type "E_catch_kg" file-type ","
;  file-type "E_com_catch" file-type "," file-type "E_rec_catch" file-type ","
  file-type "G_1" file-type ", " file-type "G_2" file-type ", " file-type "G_3" file-type ", " file-type "G_4" file-type ", " file-type "G_5" file-type ", "
  file-type "G_catch_kg"
;  file-type "G_com_catch" file-type "," file-type "G_rec_catch"
  file-print ""
  file-close
end


to write-output                                                                         ;; write annual outputs to the output file
  random-seed ( 1 )
  file-open output-filename
  ask reefs
  [
    file-type ensemble file-type "," file-type year file-type "," file-type reef_id file-type ","  file-type region_name file-type ","  file-type shelf_position file-type "," file-type rezone_year file-type "," file-type priority_category file-type "," file-type x file-type "," file-type y file-type "," file-type km_offshore file-type "," file-type reef_sites file-type ","
    file-type C_sa_r file-type "," file-type C_ta_r file-type "," file-type C_mo_r file-type "," file-type C_po_r file-type "," file-type C_fa_r file-type "," file-type C_tt_r file-type ","
    file-type C_out_degree file-type ","
    file-type dhw file-type ","
    file-type bleach_mort_sa_r file-type "," file-type bleach_mort_ta_r file-type "," file-type bleach_mort_mo_r file-type "," file-type bleach_mort_po_r file-type "," file-type bleach_mort_fa_r file-type "," file-type bleach_mort_tt_r file-type ","
    file-type cyclone_category file-type ","
    file-type cyclone_mort_sa_r file-type "," file-type cyclone_mort_ta_r file-type "," file-type cyclone_mort_mo_r file-type "," file-type cyclone_mort_po_r file-type "," file-type cyclone_mort_fa_r file-type "," file-type cyclone_mort_tt_r file-type ","
    file-type predate_mort_sa_r file-type "," file-type predate_mort_ta_r file-type "," file-type predate_mort_mo_r file-type "," file-type predate_mort_po_r file-type "," file-type predate_mort_fa_r file-type "," file-type predate_mort_tt_r file-type ","
    file-type S_1_r file-type "," file-type S_2_r file-type "," file-type S_3_r file-type "," file-type S_4_r file-type "," file-type S_5_r file-type "," file-type S_6_r file-type "," file-type S_manta_r file-type ","
    file-type dives_reef file-type ","
    file-type B_r file-type "," file-type T_r file-type ","
    file-type E_1 file-type "," file-type E_2 file-type "," file-type E_3 file-type "," file-type E_4 file-type "," file-type E_5 file-type ","
    file-type E_catch_kg file-type ","
    ;    file-type E_com_catch file-type "," file-type E_rec_catch file-type ","
    file-type G_1 file-type "," file-type G_2 file-type "," file-type G_3 file-type "," file-type G_4 file-type "," file-type G_5 file-type ","
    file-type G_catch_kg
;    file-type G_com_catch file-type "," file-type G_rec_catch
    file-print ""
  ]
  file-close
end

; Copyright 2023 CSIRO.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
7
10
848
1080
-1
-1
0.9905
1
10
1
1
1
0
0
0
1
-420
420
-530
530
1
1
1
years
30.0

BUTTON
427
24
492
79
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
500
23
566
79
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
640
23
1085
175
GBR coral cover
years
NIL
0.0
300.0
0.0
0.5
false
true
"" ""
PENS
"staghorn acropora" 1.0 0 -2674135 true "" "plot mean [ C_sa_r ] of reefs"
"tabular acropora" 1.0 0 -955883 true "" "plot mean [ C_ta_r ] of reefs"
"montipora" 1.0 0 -1184463 true "" "plot mean [ C_mo_r ] of reefs"
"poritidae" 1.0 0 -8630108 true "" "plot mean [ C_po_r ] of reefs"
"favid" 1.0 0 -10899396 true "" "plot mean [ C_fa_r ] of reefs"
"All reefs" 1.0 0 -16777216 true "" "plot mean [ C_reef ] of reefs"

CHOOSER
428
91
568
136
Network-image-shows
Network-image-shows
"Off" "Coral (fast growing)" "Coral (slow growing)" "Coral (resistant)" "CoTS (adult)"
0

PLOT
641
185
1033
337
Average adult CoTS population (CoTS per ha)
years
NIL
0.0
300.0
0.0
50.0
false
true
"" ""
PENS
"Age = 3" 1.0 0 -612749 true "" "plot ( mean [ S_3_r ] of reefs )"
"Age = 4" 1.0 0 -955883 true "" "plot ( mean [ S_4_r ] of reefs )"
"Age = 5" 1.0 0 -6995700 true "" "plot ( mean [ S_5_r ] of reefs )"
"Age = 6" 1.0 0 -13297659 true "" "plot ( mean [ S_6_r ] of reefs )"

PLOT
640
509
1032
643
Fraction of reefs with CoTS outbreaks
years
NIL
0.0
300.0
0.0
0.4
false
true
"" ""
PENS
"total" 1.0 0 -8020277 true "" "plot count reefs with [ ( 0 * S_2_r + S_3_r + S_4_r + S_5_r + S_6_r ) > 15 ] / number_of_reefs"
"active      " 1.0 0 -14730904 true "" "plot count reefs with [ ( 0 * S_2_r + S_3_r + S_4_r + S_5_r + S_6_r ) > 68 ] / number_of_reefs"

PLOT
639
653
1079
799
Monitored reef coral cover and adult COTS population
Years
NIL
0.0
300.0
0.0
0.5
false
true
"" ""
PENS
"coral cover" 1.0 0 -955883 true "" "plot monitor_C_total"
"thermally tolerant" 1.0 0 -10899396 true "" "plot monitor_C_tt"
"adult CoTS" 1.0 0 -13345367 true "" "plot monitor_S_adult / 68"

INPUTBOX
1161
83
1249
143
ensemble-runs-i
20.0
1
0
Number

INPUTBOX
1389
826
1473
886
seed-hectares-i
0.0
1
0
Number

INPUTBOX
1521
278
1619
338
CoTS-vessels-S-i
0.0
1
0
Number

INPUTBOX
1311
757
1439
817
reef-shading-reduction-i
0.0
1
0
Number

INPUTBOX
478
146
568
206
monitored-reef
694
1
0
String

INPUTBOX
1253
83
1317
143
start-year-i
1956.0
1
0
Number

INPUTBOX
1323
83
1386
143
save-year-i
1986.0
1
0
Number

INPUTBOX
1558
83
1622
143
end-year-i
2075.0
1
0
Number

INPUTBOX
1089
692
1219
752
start-rubble-consolidation-i
9999.0
1
0
Number

INPUTBOX
1570
826
1635
886
dominance-i
0.0
1
0
Number

INPUTBOX
1297
826
1384
886
seed-threshold-i
0.0
1
0
Number

INPUTBOX
1472
692
1599
752
consolidation-hectares-i
0.0
1
0
Number

INPUTBOX
1339
692
1468
752
consolidation-threshold-i
0.0
1
0
Number

INPUTBOX
1230
148
1334
208
restore-timeframe-i
0.0
1
0
Number

INPUTBOX
1613
627
1714
687
intervene-lat-min-i
-25.0
1
0
Number

INPUTBOX
1609
495
1713
555
intervene-lat-max-i
-9.0
1
0
Number

INPUTBOX
1227
627
1374
687
regional-shading-reduction-i
0.0
1
0
Number

INPUTBOX
1092
213
1224
273
start-CoTS-control-i
9999.0
1
0
Number

INPUTBOX
1226
826
1292
886
seed-reefs-i
0.0
1
0
Number

INPUTBOX
1225
758
1306
818
shading-reefs-i
0.0
1
0
Number

INPUTBOX
1225
692
1334
752
consolidation-reefs-i
0.0
1
0
Number

INPUTBOX
1478
826
1565
886
hybrid-fraction-i
0.0
1
0
Number

MONITOR
576
23
632
80
 Year
year
0
1
14

INPUTBOX
1299
959
1385
1019
pH-protection-i
0.0
1
0
Number

INPUTBOX
1418
278
1517
338
CoTS-vessels-C-i
0.0
1
0
Number

INPUTBOX
1315
278
1414
338
CoTS-vessels-N-i
0.0
1
0
Number

TEXTBOX
249
31
411
72
CoCoNet
36
86.0
1

INPUTBOX
1229
212
1340
272
eco-threshold-i
8.0
1
0
Number

INPUTBOX
1209
10
1319
70
output-filename
I_2p6.csv
1
0
String

INPUTBOX
1226
959
1294
1019
pH-reefs-i
0.0
1
0
Number

PLOT
640
347
1065
499
Fish abundances
Years
NIL
0.0
300.0
0.0
2.0
false
true
"" ""
PENS
"Benthic Invert" 1.0 0 -6459832 true "" "plot mean [ B ] of sites / B_max"
"Triggerfish" 1.0 0 -5987164 true "" "plot mean [ T ] of sites / T_max"
"Adult emperors" 1.0 0 -13840069 true "" "plot mean [ E_2 + E_3 + E_4 + E_5 ] of reefs / 20"
"Adult groupers" 1.0 0 -955883 true "" "plot mean [ G_2 + G_3 + G_4 + G_5 ] of reefs / 70"

INPUTBOX
1207
278
1310
338
CoTS-vessels-FN-i
0.0
1
0
Number

INPUTBOX
1552
561
1655
621
intervene-lon-min-i
140.0
1
0
Number

INPUTBOX
1662
561
1769
621
intervene-lon-max-i
155.0
1
0
Number

INPUTBOX
1092
148
1225
208
start-catchment-restore-i
9999.0
1
0
Number

INPUTBOX
1089
758
1219
818
start-reef-shading-i
9999.0
1
0
Number

INPUTBOX
1089
627
1222
687
start-regional-shading-i
9999.0
1
0
Number

INPUTBOX
1089
959
1219
1019
start-pH-protection-i
9999.0
1
0
Number

INPUTBOX
1089
826
1218
886
start-coral-seeding-i
9999.0
1
0
Number

INPUTBOX
1089
893
1219
953
start-coral-slick-i
9999.0
1
0
Number

INPUTBOX
1226
893
1293
953
slick-reefs-i
0.0
1
0
Number

INPUTBOX
1298
893
1385
953
slick-threshold-i
0.0
1
0
Number

INPUTBOX
1390
893
1473
953
slick-hectares-i
0.0
1
0
Number

INPUTBOX
1391
83
1478
143
projection-year-i
2025.0
1
0
Number

INPUTBOX
1092
346
1223
406
start-modified-zoning-i
9999.0
1
0
Number

INPUTBOX
1230
345
1319
405
rezoned-reefs-i
0.0
1
0
Number

INPUTBOX
1228
495
1347
555
start-upper-sizelimit-i
9999.0
1
0
Number

INPUTBOX
1354
494
1443
554
start-CoTSlimit-i
9999.0
1
0
Number

INPUTBOX
1482
83
1554
143
search-year-i
9999.0
1
0
Number

INPUTBOX
1230
411
1320
471
catch-reduction-i
0.0
1
0
Number

INPUTBOX
1089
561
1221
621
start-emperor-release-i
9999.0
1
0
Number

INPUTBOX
1226
561
1307
621
release-reefs-i
500.0
1
0
Number

INPUTBOX
1312
561
1421
621
release-threshold-i
9999999.0
1
0
Number

INPUTBOX
1425
561
1525
621
release-number-i
0.0
1
0
Number

INPUTBOX
1089
496
1221
556
start-lower-sizelimit-i
9999.0
1
0
Number

INPUTBOX
1092
412
1224
472
start-modified-fishing-i
9999.0
1
0
Number

INPUTBOX
1092
83
1154
143
SSP-i
2.6
1
0
Number

INPUTBOX
1091
11
1204
71
parameter-filename
null.csv
1
0
String

INPUTBOX
1092
278
1203
338
CoTS-vessels-GBR-i
0.0
1
0
Number

INPUTBOX
1345
211
1443
271
CoTS-threshold-i
999999.0
1
0
Number

INPUTBOX
1448
210
1544
270
coral-threshold-i
0.0
1
0
Number

INPUTBOX
1623
278
1745
338
CoTS-vessels-sector-i
0.0
1
0
Number

CHOOSER
1337
10
1515
55
Perfect-intervention
Perfect-intervention
"None" "Starfish-control" "Coral-replenishment" "Coral-enhancement" "Coral-shading" "Fish-protection" "Rubble-stabilisation" "ShadingPlusControl"
0

SWITCH
1523
11
1685
44
Unregulated-fishing?
Unregulated-fishing?
1
1
-1000

@#$#@#$#@
## BACKGROUND

This is version 3.0 of The Coral and Community Network (CoCoNet) model. 

Version 1.0 is described in:

Condie, S. A., E. E. Plaganyi, E. B. Morello, K. Hock, and R. Beeden. 2018. Great Barrier Reef recovery through multiple interventions. Conservation Biology 32:1356-1367.

Version 2.0 is described in:

Condie, S. A., K. R. N. Anthony, R. C. Babcock, M. E. Baird, R. Beeden, C. S. Fletcher, R. Gorton, D. Harrison, A. J. Hobday, E. E. Plaganyi, and D. A. Westcott. 2021. Large-scale interventions may delay decline of the Great Barrier Reef. Royal Society Open Science 8.

Condie, S. A. 2022. Changing the climate risk trajectory for coral reefs. Frontiers in Climate 4.


Versions 2.0 and 3.0 are configured for the Great Barrier Reef (GBR), but can be adapted to other coral reef systems.  


## MODELING ENVIRONMENT

The CoCoNet model runs within the NetLogo multi-agent programmable modeling environment, which can be downloaded free of charge at https://ccl.northwestern.edu/netlogo/ . 
CoCoNet 3.0 runs on Netlogo 6.2.  


## MODEL PURPOSE

CoCoNet is a reef meta-community model designed to explore and understand the fate of coral reefs under cumulative pressures of:
- predation by crown-of-thorns starfish (CoTS);
- coral bleaching;
- tropical cyclones;
- terrestrial run-off during floods;
- ocean acidification. 

It can be used to evaluate a range of reef management interventions including.;
- CoTS control;
- fisheries zoning;
- outplanting bleaching resistant coral nubbins;
- shading of individual reefs to reduce bleaching;
- regional cloud brightening to reduce bleaching;
- stabilisation of coral rubble to enhance coral recruitment.


## MODEL DESCRIPTION

CoCoNet consists of a dynamic network of individual coral reefs connected through larval recruitment. Reefs support populations of:
- 6 coral groups;
- age-structured crown-of-thorns starfish (CoTS) that prey on coral;
- a benthic invertebrate group that prey on CoTS (e.g. decorator crab);
- damselfish that prey on CoTS larvae;
- triggerfish that prey on benthic invertebrates;
- emperor fish that prey on juvenile and adult CoTS;
- grouper fish that prey on damselfish and triggerfish.
In addition to their trophic interactions, these groups may respond to environmental stressors and management interventions.


## GRAPHICAL INTERFACE

The model is run by first selecting setup in the Interface to initialise the reef network configuration, and then selecting run. Deselecting "view updates" will dramatically increase the run speed.

The Interface also includes:
- a dynamic map showing reef connections and reef populations;
- time-series of average reef populations and percentage of reefs with CoTS outbreaks.
These elements are updated at every model timestep (annual).

The Interface also allows the user to specify:
- the CMIP6 climate scenario
 runtime information and parameters related to interventions.

## INPUT FILES

The only additional files required to run CoCoNet are:
- 'Coastline.csv' containing longitudes and latitudes of the coastline at relatively coarse scale.
-  'Reefs2023.csv' containing all required reef characteristics, including dispersal kernels derived from the eReefs GBR1 model.

## OUTPUT FILES

Model results are saved on an annual time-step for every reef in the output file with columns for all biological populations, selected biological rates, and key intervention characteristics.


## COPYRIGHT AND LICENSE

Copyright 2022 CSIRO

![CC BY-NC-SA 3.0](http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cloud
false
0
Circle -7500403 true true 13 118 94
Circle -7500403 true true 86 101 127
Circle -7500403 true true 51 51 108
Circle -7500403 true true 118 43 95
Circle -7500403 true true 158 68 134

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

eyeball
false
0
Circle -1 true false 22 20 248
Circle -7500403 true true 83 81 122
Circle -16777216 true false 122 120 44

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

pushpin
false
0
Polygon -7500403 true true 130 158 105 180 93 205 119 196 142 173
Polygon -16777216 true false 121 112 111 128 109 143 112 158 123 175 138 184 156 189 169 188 186 177 199 158 139 98
Circle -7500403 true true 126 86 90
Polygon -16777216 true false 159 103 152 114 151 125 152 135 158 144 169 150 182 151 194 149 207 142 238 111 191 72
Polygon -16777216 true false 187 56 177 72 175 87 178 102 189 119 204 128 222 133 235 132 252 121 265 102 205 42
Circle -7500403 true true 190 30 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

sun
false
0
Circle -7500403 true true 75 75 150
Polygon -7500403 true true 300 150 240 120 240 180
Polygon -7500403 true true 150 0 120 60 180 60
Polygon -7500403 true true 150 300 120 240 180 240
Polygon -7500403 true true 0 150 60 120 60 180
Polygon -7500403 true true 60 195 105 240 45 255
Polygon -7500403 true true 60 105 105 60 45 45
Polygon -7500403 true true 195 60 240 105 255 45
Polygon -7500403 true true 240 195 195 240 255 255

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

tree_coconut
false
3
Polygon -6459832 true true 144 67 150 68 134 126 132 179 143 247 133 247 125 179 125 137 132 106
Polygon -10899396 true false 228 141 211 116 227 122 200 103 217 106 188 93 213 96 173 75 191 80 154 61 136 75 154 67 171 85 168 76 186 103 184 88 196 114 195 105 204 126 203 114 213 127
Polygon -10899396 true false 72 141 89 116 73 122 100 103 83 106 112 93 87 96 127 75 109 80 146 61 164 75 146 67 129 85 132 76 114 103 116 88 104 114 105 105 96 126 97 114 87 128
Polygon -10899396 true false 147 68 174 81 152 77 185 94 164 90 180 113 168 106 172 133 164 110 163 116 156 90 156 112 148 80 146 88

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="S2_mort">
      <value value="2.0E-4"/>
      <value value="4.0E-4"/>
      <value value="6.0E-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="S1_mort">
      <value value="0.003"/>
      <value value="0.005"/>
      <value value="0.007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="S_recruit">
      <value value="2"/>
      <value value="5"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_recruit">
      <value value="0.02"/>
      <value value="0.05"/>
      <value value="0.08"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="G_recruit">
      <value value="0.004"/>
      <value value="0.012"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="E_recruit">
      <value value="0.05"/>
      <value value="0.15"/>
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
