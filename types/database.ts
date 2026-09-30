export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

type Table<Row, Insert, Update = Partial<Insert>> = {
  Row: Row;
  Insert: Insert;
  Update: Update;
  Relationships: [];
};

export type Database = {
  public: {
    Tables: {
      roles: Table<
        {
          id: string;
          name: "ADMIN" | "COLLABORATOR";
          description: string | null;
        },
        {
          id?: string;
          name: "ADMIN" | "COLLABORATOR";
          description?: string | null;
        }
      >;
      users: Table<
        {
          id: string;
          business_id: string;
          auth_user_id: string;
          full_name: string;
          email: string | null;
          phone: string | null;
          role_id: string;
          is_active: boolean;
          created_at: string;
          updated_at: string;
          last_login_at: string | null;
        },
        {
          id?: string;
          business_id: string;
          auth_user_id: string;
          full_name: string;
          email?: string | null;
          phone?: string | null;
          role_id: string;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
          last_login_at?: string | null;
        }
      >;
    };
    Views: Record<string, never>;
    Functions: {
      current_business_id: {
        Args: Record<string, never>;
        Returns: string | null;
      };
      current_user_role: {
        Args: Record<string, never>;
        Returns: "ADMIN" | "COLLABORATOR" | null;
      };
      is_admin: { Args: Record<string, never>; Returns: boolean };
    };
    Enums: { user_role: "ADMIN" | "COLLABORATOR" };
    CompositeTypes: Record<string, never>;
  };
};

export type UserProfile = Pick<
  Database["public"]["Tables"]["users"]["Row"],
  "id" | "business_id" | "full_name" | "email" | "role_id" | "is_active"
> & {
  role: Database["public"]["Tables"]["roles"]["Row"]["name"];
};
