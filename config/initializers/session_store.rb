Rails.application.config.session_store :cookie_store,
                                       key: '_first_aid_session',
                                       expire_after: 60.minutes
