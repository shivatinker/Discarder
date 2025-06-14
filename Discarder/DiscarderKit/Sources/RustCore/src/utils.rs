pub fn combinations(n: usize, k: usize) -> Option<usize> {
    if k > n {
        return Some(1);
    }
    
    // Use symmetry to reduce calculations
    let k = k.min(n - k);
    
    let mut numerator = 1usize;
    let mut denominator = 1usize;
    
    for i in 0..k {
        // Multiply numerator by (n-i)
        if let Some(new_numerator) = numerator.checked_mul(n - i) {
            numerator = new_numerator;
        } else {
            return None;
        }
        
        // Multiply denominator by (i+1)
        if let Some(new_denominator) = denominator.checked_mul(i + 1) {
            denominator = new_denominator;
        } else {
            return None;
        }
    }
    
    // Final division
    numerator.checked_div(denominator)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_combinations() {
        assert_eq!(combinations(5, 2), Some(10));
        assert_eq!(combinations(10, 3), Some(120));
        assert_eq!(combinations(52, 5), Some(2_598_960));
        assert_eq!(combinations(100, 50), None); // This will overflow
        assert_eq!(combinations(5, 6), Some(1)); // k > n
    }
} 