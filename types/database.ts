export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

type Table<Row, Insert, Update = Partial<Insert>, Relationships = []> = {
  Row: Row;
  Insert: Insert;
  Update: Update;
  Relationships: Relationships;
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
      categories: Table<
        {
          id: string;
          business_id: string;
          name: string;
          slug: string;
          description: string | null;
          image_url: string | null;
          sort_order: number;
          is_active: boolean;
          created_at: string;
          updated_at: string;
        },
        {
          id?: string;
          business_id: string;
          name: string;
          slug: string;
          description?: string | null;
          image_url?: string | null;
          sort_order?: number;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        }
      >;
      products: Table<
        {
          id: string;
          business_id: string;
          category_id: string | null;
          name: string;
          slug: string;
          short_description: string | null;
          description: string | null;
          sku: string | null;
          sale_price: number;
          cost_price: number | null;
          track_inventory: boolean;
          minimum_stock: number;
          is_featured: boolean;
          status: Database["public"]["Enums"]["product_status"];
          sort_order: number;
          created_at: string;
          updated_at: string;
        },
        {
          id?: string;
          business_id: string;
          category_id?: string | null;
          name: string;
          slug: string;
          short_description?: string | null;
          description?: string | null;
          sku?: string | null;
          sale_price?: number;
          cost_price?: number | null;
          track_inventory?: boolean;
          minimum_stock?: number;
          is_featured?: boolean;
          status?: Database["public"]["Enums"]["product_status"];
          sort_order?: number;
          created_at?: string;
          updated_at?: string;
        },
        Partial<{
          id: string;
          business_id: string;
          category_id: string | null;
          name: string;
          slug: string;
          short_description: string | null;
          description: string | null;
          sku: string | null;
          sale_price: number;
          cost_price: number | null;
          track_inventory: boolean;
          minimum_stock: number;
          is_featured: boolean;
          status: Database["public"]["Enums"]["product_status"];
          sort_order: number;
          created_at: string;
          updated_at: string;
        }>,
        [
          {
            foreignKeyName: "products_category_id_fkey";
            columns: ["category_id"];
            isOneToOne: false;
            referencedRelation: "categories";
            referencedColumns: ["id"];
          },
        ]
      >;
      product_images: Table<
        {
          id: string;
          product_id: string;
          storage_path: string;
          public_url: string | null;
          alt_text: string | null;
          sort_order: number;
          is_primary: boolean;
          created_at: string;
        },
        {
          id?: string;
          product_id: string;
          storage_path: string;
          public_url?: string | null;
          alt_text?: string | null;
          sort_order?: number;
          is_primary?: boolean;
          created_at?: string;
        },
        Partial<{
          id: string;
          product_id: string;
          storage_path: string;
          public_url: string | null;
          alt_text: string | null;
          sort_order: number;
          is_primary: boolean;
          created_at: string;
        }>,
        [
          {
            foreignKeyName: "product_images_product_id_fkey";
            columns: ["product_id"];
            isOneToOne: false;
            referencedRelation: "products";
            referencedColumns: ["id"];
          },
        ]
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
      register_product_image: {
        Args: {
          p_product_id: string;
          p_storage_path: string;
          p_alt_text: string;
        };
        Returns: string;
      };
      set_product_image_primary: {
        Args: { p_product_id: string; p_image_id: string };
        Returns: undefined;
      };
      move_product_image: {
        Args: {
          p_product_id: string;
          p_image_id: string;
          p_direction: number;
        };
        Returns: undefined;
      };
    };
    Enums: {
      product_status: "DRAFT" | "PUBLISHED" | "HIDDEN" | "OUT_OF_STOCK";
      user_role: "ADMIN" | "COLLABORATOR";
    };
    CompositeTypes: Record<string, never>;
  };
};

export type UserProfile = Pick<
  Database["public"]["Tables"]["users"]["Row"],
  "id" | "business_id" | "full_name" | "email" | "role_id" | "is_active"
> & {
  role: Database["public"]["Tables"]["roles"]["Row"]["name"];
};
