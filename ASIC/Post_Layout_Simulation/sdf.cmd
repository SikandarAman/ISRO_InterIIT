(COMMENT "Apply post-layout SDF delays")
(SDF_FILE "design_post.sdf"
    (CELL
        (CELLTYPE "integrator_chain_with_downsampler_comb_nohold_with_fir128")
        (INSTANCE uut)   ; <- change 'uut' to your DUT instance name if different
        (DELAY_TYPE MAXIMUM)
    )
)

