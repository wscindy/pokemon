player1_hperDiagram
    USERS {
        int id PK
        string email UK
        string name
        string uid
        string provider
        string avatar_url
        string online_status
        timestamp created_at
        timestamp updated_at
    }

    CARDS {
        int id PK
        string card_unique_id UK
        string name
        string img_url
        string card_type
        int hp
        string stage
        int pokedex_number
        string evolve_from
        string regulation_mark
        string set_name
        string set_full_name
        string set_number
        text rule_box
        text tera_effect
        string weakness_type
        string weakness_value
        string resistance_type
        string resistance_value
        int retreat_cost
        jsonb raw_json
        timestamp created_at
        timestamp updated_at
    }

    CARD_TYPES {
        int id PK
        string card_unique_id FK
        string type_name
    }

    ATTACKS {
        int id PK
        string card_unique_id FK
        string name
        string damage
        int position
        text effect_description
        timestamp created_at
        timestamp updated_at
    }

    ATTACK_ENERGY_COSTS {
        int id PK
        int attack_id FK
        string energy_type
        int energy_count
    }

    CARD_ABILITIES {
        int id PK
        string card_unique_id FK
        string name
        text effect
    }

    CARD_TAGS {
        int id PK
        string card_unique_id FK
        string tag_name
    }

    USER_CARDS {
        int id PK
        int user_id FK
        string card_unique_id FK
        boolean is_active
        timestamp created_at
    }

    ROOMS {
        int id PK
        string name
        string room_type
        string password
        int creator_id FK
        string status
        int max_players
        timestamp created_at
        timestamp updated_at
    }

    ROOM_PARTICIPANTS {
        int id PK
        int room_id FK
        int user_id FK
        string role
        boolean ready_status
        timestamp joined_at
    }

    GAME_STATES {
        int id PK
        int room_id FK
        int player1_id FK
        int player2_id FK
        int current_turn_user_id FK
        int round_number
        int player1_hp
        int player2_hp
        string status
        int winner_id FK
        timestamp created_at
        timestamp updated_at
    }

    MESSAGES {
        int id PK
        int room_id FK
        int user_id FK
        text content
        string message_type
        timestamp created_at
    }

    CARDS ||--o{ CARD_TYPES : "has"
    CARDS ||--o{ ATTACKS : "has"
    CARDS ||--o{ CARD_ABILITIES : "has"
    CARDS ||--o{ CARD_TAGS : "has"
    ATTACKS ||--o{ ATTACK_ENERGY_COSTS : "requires"
    USERS ||--o{ ROOMS : "creates"
    USERS ||--o{ USER_CARDS : "owns"
    CARDS ||--o{ USER_CARDS : "belongs_to"
    USERS ||--o{ ROOM_PARTICIPANTS : "joins"
    ROOMS ||--o{ ROOM_PARTICIPANTS : "has"
    ROOMS ||--|| GAME_STATES : "has_game"
    USERS ||--o{ MESSAGES : "sends"
    ROOMS ||--o{ MESSAGES : "contains"
    USERS ||--o{ GAME_STATES : "plays_as_p1"
    USERS ||--o{ GAME_STATES : "plays_as_p2"
    USERS ||--o{ GAME_STATES : "current_turn"