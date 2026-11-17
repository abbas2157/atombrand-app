<?php
// Local demo brand for running the app against XAMPP (never production).
// Re-running replaces only its own rows (logins ending @zenvo.test and the
// brand slug zenvo-appliances-demo); nothing else is touched.
//
//   cd C:\xampp\htdocs\atomshop
//   php artisan tinker C:\MyProject\atombrand-app\tool\seed_local_demo_brand.php
//
// Sign in as brand owner:  demo-owner@zenvo.test  /  ZenvoDemo-2026
// Team member (orders):    0300 0000001           /  ZenvoDemo-2026

use App\Models\{Brand, BrandFeature, BrandOutlet, BrandRole, BrandTeamMember, BulkOrder, Cart, Order, Product, Seller, SourcingEvent, User};
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

const DEMO_PASSWORD = 'ZenvoDemo-2026';

if (app()->environment('production') || ! in_array(config('database.connections.mysql.host'), ['127.0.0.1', 'localhost'], true)) {
    throw new RuntimeException('Local database only.');
}

// Remove an earlier run's rows.
DB::transaction(function () {
    $old = Brand::where('slug', 'zenvo-appliances-demo')->first();
    $oldUsers = User::withTrashed()->where('email', 'like', '%@zenvo.test')->pluck('id');
    if ($old) {
        $requests = BulkOrder::withoutGlobalScopes()->where('brand_id', $old->id)->pluck('id');
        SourcingEvent::whereIn('bulk_order_id', $requests)->delete();
        BulkOrder::withoutGlobalScopes()->whereIn('id', $requests)->delete();
        BrandTeamMember::where('brand_id', $old->id)->delete();
        BrandFeature::where('brand_id', $old->id)->delete();
        BrandOutlet::where('brand_id', $old->id)->delete();
        Product::withoutGlobalScopes()->where('brand_id', $old->id)->delete();
        DB::table('billing_accounts')->where('account_type', 'brand')->where('account_id', $old->id)->delete();
        DB::table('brand_devices')->where('brand_id', $old->id)->delete();
        $old->delete();
    }
    $carts = Cart::whereIn('user_id', $oldUsers)->pluck('id');
    Order::withoutGlobalScopes()->whereIn('cart_id', $carts)->delete();
    Cart::whereIn('id', $carts)->delete();
    Seller::withoutGlobalScopes()->whereIn('user_id', $oldUsers)->delete();
    \App\Models\Notification::whereIn('to_user_id', $oldUsers)->delete();
    DB::table('personal_access_tokens')->where('tokenable_type', User::class)->whereIn('tokenable_id', $oldUsers)->delete();
    User::withTrashed()->whereIn('id', $oldUsers)->forceDelete();
});

DB::transaction(function () {
    $user = function (string $role, string $name, string $email, string $phone): User {
        $u = User::create([
            'uuid' => (string) Str::uuid(), 'name' => $name, 'email' => $email, 'phone' => $phone,
            'password' => bcrypt(DEMO_PASSWORD), 'role' => $role,
        ]);
        $u->forceFill(['status' => 'active'])->save();
        return $u;
    };

    $owner = $user('brand', 'Asad Raza', 'demo-owner@zenvo.test', '03214567890');
    $brand = Brand::create(['title' => 'Zenvo Appliances', 'slug' => 'zenvo-appliances-demo', 'status' => 'active', 'user_id' => $owner->id]);
    $brand->forceFill(['portal_version' => 'v2', 'account_type' => 'multi', 'outlet_limit' => 5])->save();

    // A paid yearly package, so offline working and every screen are on.
    DB::table('billing_accounts')->updateOrInsert(
        ['account_type' => 'brand', 'account_id' => $brand->id],
        ['shop_type' => 'multi', 'status' => 'active', 'period_months' => 12,
         'period_starts_on' => now()->subMonths(2)->toDateString(), 'period_ends_on' => now()->addMonths(10)->toDateString(),
         'created_at' => now(), 'updated_at' => now()],
    );

    foreach (['inventory', 'offline', 'team', 'ask_atom', 'alerts'] as $key) {
        BrandFeature::create(['brand_id' => $brand->id, 'feature' => $key, 'status' => 'active', 'monthly_price' => 0, 'starts_at' => now()->toDateString()]);
    }

    BrandOutlet::create(['brand_id' => $brand->id, 'name' => 'Lahore · Gulberg', 'address' => '12 Main Boulevard, Gulberg III', 'phone' => '04235761234', 'is_main' => true, 'status' => 'open', 'opened_on' => now()->subYear()->toDateString()]);
    BrandOutlet::create(['brand_id' => $brand->id, 'name' => 'Karachi · Tariq Road', 'address' => 'Shop 8, Tariq Road', 'phone' => '02134551234', 'is_main' => false, 'status' => 'open', 'opened_on' => now()->subMonths(4)->toDateString()]);

    $products = [];
    foreach ([
        ['Zenvo 1.5 Ton Inverter AC', 149999], ['Zenvo 55in 4K Smart TV', 124999], ['Zenvo 43in Smart LED', 69999],
        ['Zenvo Double Door Fridge 14 cft', 112500], ['Zenvo Front Load Washer 8kg', 98000], ['Zenvo Microwave 30L', 32999],
    ] as [$title, $price]) {
        $products[] = Product::create([
            'uuid' => (string) Str::uuid(), 'title' => $title, 'detail_page_title' => $title,
            'slug' => Str::slug($title).'-'.Str::random(6), 'price' => $price, 'min_advance_price' => (int) ($price / 5),
            'brand_id' => $brand->id, 'category_id' => 1, 'status' => 'Published',
        ]);
    }

    $i = 0;
    foreach ([
        ['Bilal Ahmed', 'Pending', 0, 1], ['Sana Malik', 'Pending', 1, 1], ['Usman Tariq', 'Pending', 2, 2],
        ['Hira Shah', 'Varification', 3, 1], ['Kamran Ali', 'Processing', 0, 1], ['Ayesha Noor', 'Processing', 4, 1],
        ['Faisal Iqbal', 'Delivered', 5, 2], ['Nadia Khan', 'Completed', 1, 1], ['Omar Farooq', 'Cancelled', 2, 1],
    ] as [$name, $status, $p, $qty]) {
        $i++;
        $buyer = $user('customer', $name, "demo-buyer-$i@zenvo.test", '0333'.(1000000 + $i));
        $product = $products[$p];
        $cart = new Cart;
        $cart->forceFill(['user_id' => $buyer->id, 'product_id' => $product->id, 'product_price' => $product->price,
            'product_advance_price' => $product->price, 'quantity' => $qty, 'tenure' => 1, 'status' => 'Purchased'])->save();
        $order = new Order;
        $order->forceFill(['uuid' => (string) Str::uuid(), 'user_id' => $buyer->id, 'cart_id' => $cart->id,
            'total_deal_price' => $product->price * $qty, 'advance_price' => $product->price * $qty,
            'instalment_tenure' => 1, 'portal' => 'Web', 'status' => $status])->save();
        $order->forceFill(['created_at' => now()->subHours($i * 5)])->saveQuietly();
    }

    // Team member on the ready-made "orders" role.
    $agent = $user('brand_agent', 'Hamza Saleem', 'demo-agent@zenvo.test', '03000000001');
    BrandTeamMember::create(['brand_id' => $brand->id, 'user_id' => $agent->id,
        'brand_role_id' => BrandRole::whereNull('brand_id')->where('key', 'orders')->value('id'),
        'scope' => 'all', 'must_change_password' => false]);

    // Two seller sourcing requests and a website bulk request.
    foreach ([['Madina Electronics', 'Zenvo 55in 4K Smart TV', 12, 112000], ['Hall Road Traders', 'Zenvo 1.5 Ton Inverter AC', 20, 138000]] as $k => [$biz, $title, $qty, $target]) {
        $login = $user('seller', "$biz Owner", "demo-seller-$k@zenvo.test", '0345'.(1000000 + $k));
        $seller = new Seller;
        $seller->forceFill(['user_id' => $login->id, 'name' => "$biz Owner", 'business_name' => $biz,
            'code' => random_int(10000, 99999), 'verified' => '1', 'dashboard_version' => 'v2'])->save();
        $req = BulkOrder::create(['full_name' => $biz, 'phone' => $login->phone, 'product_title' => $title,
            'brand_id' => $brand->id, 'quantity' => $qty, 'target_price' => $target, 'needed_by' => now()->addDays(5)->toDateString(),
            'address' => 'Hall Road, Lahore', 'user_id' => $login->id, 'seller_id' => $seller->id,
            'source' => BulkOrder::SOURCE_SOURCING, 'status' => 'New Lead', 'portal' => 'App', 'type' => 'atomshop']);
        \App\Services\SourcingService::event($req, 'seller', 'requested', "$qty × $title");
    }
    BulkOrder::create(['full_name' => 'Pearl Continental Hotels', 'phone' => '03001112233', 'product_title' => 'Zenvo 43in Smart LED',
        'product_id' => $products[2]->id, 'brand_id' => $brand->id, 'quantity' => 40, 'target_price' => 62000,
        'needed_by' => now()->addDays(14)->toDateString(), 'address' => 'Shahrah-e-Quaid-e-Azam, Lahore',
        'status' => 'New Lead', 'portal' => 'Web', 'type' => 'atomshop']);
});

echo "Demo brand ready: Zenvo Appliances.\n";
