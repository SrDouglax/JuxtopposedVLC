/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
static void UpdateDefaultLiveStyles( filter_t *p_filter )
{
    filter_sys_t *p_sys = p_filter->p_sys;
    text_style_t *p_style = p_sys->p_default_style;
    p_style->i_font_size = var_InheritInteger(p_filter, "freetype-absolute-size");

    p_style->i_font_color = var_InheritInteger( p_filter, "freetype-color" );

    p_style->i_background_alpha = var_InheritInteger( p_filter, "freetype-background-opacity" );
    p_style->i_background_color = var_InheritInteger( p_filter, "freetype-background-color" );

    p_sys->i_outline_thickness = var_InheritInteger( p_filter, "freetype-outline-thickness" );
}

static void FillDefaultStyles( filter_t *p_filter )
{
    filter_sys_t *p_sys = p_filter->p_sys;

#ifdef HAVE_GET_FONT_BY_FAMILY_NAME
    p_sys->p_default_style->psz_fontname = var_InheritString( p_filter, "freetype-font" );
#endif
    /* Set default psz_fontname */
    if( !p_sys->p_default_style->psz_fontname || !*p_sys->p_default_style->psz_fontname )
    {
        free( p_sys->p_default_style->psz_fontname );
        p_sys->p_default_style->psz_fontname = strdup( DEFAULT_FAMILY );
    }

#ifdef HAVE_GET_FONT_BY_FAMILY_NAME
    p_sys->p_default_style->psz_monofontname = var_InheritString( p_filter, "freetype-monofont" );
#endif
    /* set default psz_monofontname */
    if( !p_sys->p_default_style->psz_monofontname || !*p_sys->p_default_style->psz_monofontname )
    {
        free( p_sys->p_default_style->psz_monofontname );
        p_sys->p_default_style->psz_monofontname = strdup( DEFAULT_MONOSPACE_FAMILY );
    }

    UpdateDefaultLiveStyles( p_filter );

    p_sys->p_default_style->i_font_alpha = var_InheritInteger( p_filter, "freetype-opacity" );

    p_sys->p_default_style->i_outline_alpha = var_InheritInteger( p_filter, "freetype-outline-opacity" );
    p_sys->p_default_style->i_outline_color = var_InheritInteger( p_filter, "freetype-outline-color" );

    p_sys->p_default_style->i_shadow_alpha = var_InheritInteger( p_filter, "freetype-shadow-opacity" );
    p_sys->p_default_style->i_shadow_color = var_InheritInteger( p_filter, "freetype-shadow-color" );
    p_sys->p_default_style->e_blending_mode = var_InheritInteger( p_filter, "freetype-blending-mode" );
    p_sys->p_default_style->i_features |= STYLE_HAS_BLENDING_MODE;

    p_sys->p_default_style->i_style_flags |= STYLE_SHADOW;
    p_sys->p_default_style->i_features |= STYLE_HAS_FLAGS;

    if( var_InheritBool( p_filter, "freetype-bold" ) )
    {
        p_sys->p_forced_style->i_style_flags |= STYLE_BOLD;
        p_sys->p_forced_style->i_features |= STYLE_HAS_FLAGS;
    }

    /* Apply forced styles to defaults, if any */
    text_style_Merge( p_sys->p_default_style, p_sys->p_forced_style, true );

}
